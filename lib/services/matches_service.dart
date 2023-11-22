import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfirstapp/globals.dart';

class MatchesService {
  //get instance of auth and firestore
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  late int sharedTags;
  late double swipingScore;
  late int ageDiff;
  late int countryCoeff;
  late double rank; // will hold the rank of the current potential match
  late double distance;
  final int distancWeight;
  final int tagsWeight;
  final int originCountryWeight;
  final int ageWeight;
  final int swipeWeight;

  // will hold the emails of the potential matches
  late List<dynamic> potentialMatchesEmails = [];
  late List<dynamic> currentUserMatches = [];
  late List<dynamic> currentUserSwipedRight = [];
  late List<dynamic> currentUserSwipedLeft = [];

  // initiating a constructor with the formula default weights
  // in the future, relate to the option of customed weights
  MatchesService(
      {this.distancWeight = 50,
      this.tagsWeight = 30,
      this.originCountryWeight = 7,
      this.ageWeight = 10,
      this.swipeWeight = 3});

  double calcGrade(DocumentSnapshot document) {
    // will hold the potential match fields
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

    data['country'] == currentUser.originCountry
        ? countryCoeff = 1
        : countryCoeff = 0;
    swipingScore = scoreBasedOnSwiping(data['swipedLeft'], data['swipedRight']);
    sharedTags = sharedTagsAmount(data['tags']);
    ageDiff = getAgeDiff(data['age']);
    // todo: change it to a distance method when we choose a suitable package
    distance = 0;
    rank = getFinalRank();
    return rank;
  }

// A method that returns the number of shared tags between the current
// user and the current potential match
  int sharedTagsAmount(List<String> potentialMatchtags) {
    int sharedTagsCounter = 0;
    for (String tag in currentUser.tags) {
      if (potentialMatchtags.contains(tag)) {
        sharedTagsCounter++;
      }
    }
    return sharedTagsCounter;
  }

// A method that returns the age difference between the current user and the
// current potential match
  int getAgeDiff(int potentialMatchAge) {
    return (potentialMatchAge - currentUser.age).abs();
  }

// A method that checks if the current user and the current potential match
// have already swiped each other and gives a suitable score
  double scoreBasedOnSwiping(List<String> potentialMatchSwipedLeft,
      List<String> potentialMatchSwipedRight) {
    // the potential match swiped the current user left

    // todo: check if the matches list will contain emails/usernames/something else...
    if (potentialMatchSwipedLeft.contains(currentUser.email)) {
      return 0;
    }
    // the potential match swiped the current user right
    if (potentialMatchSwipedRight.contains(currentUser.email)) {
      return swipeWeight.toDouble();
    }
    // the potential match has not swiped the current user yet
    return (swipeWeight / 2).toDouble();
  }

  double getFinalRank() {
    return (tagsWeight / 10) * sharedTags +
        (distancWeight - distance * (distancWeight / 20000)) +
        (ageWeight - ageDiff * (ageWeight / 81)) +
        countryCoeff * originCountryWeight +
        swipingScore;
  }

  //get potential matches
  Widget loadPotenitalMatches() {
    return StreamBuilder(
        stream: _fireStore.collection('users').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot1) {
          return StreamBuilder(
              stream: _fireStore
                  .collection('users')
                  .doc(currentUser.email)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot2) {
                if (snapshot1.hasError || snapshot2.hasError) {
                  return const Text('error');
                }
                if (snapshot1.connectionState == ConnectionState.waiting ||
                    snapshot2.connectionState == ConnectionState.waiting) {
                  return const Text('loading...');
                }
                try {
                  currentUserMatches = snapshot2.data!.get('matches');
                  currentUserSwipedRight = snapshot2.data!.get('swipedRight');
                  currentUserSwipedLeft = snapshot2.data!.get('swipedLeft');

                  for (DocumentSnapshot doc in snapshot1.data!.docs) {
                    String currentDocEmail = doc.get('email');
                    if (currentDocEmail != currentUser.email &&
                        !currentUserMatches.contains(currentDocEmail) &&
                        !currentUserSwipedRight.contains(currentDocEmail) &&
                        !currentUserSwipedLeft.contains(currentDocEmail)) {
                      potentialMatchesEmails.add(currentDocEmail);
                    }
                  }
                  print(potentialMatchesEmails);
                  // todo: replace it with a stack of cards or something like that
                  return Text('');
                } catch (e) {
                  print(e);
                  return Text('');
                }
              });
        });
  }
}

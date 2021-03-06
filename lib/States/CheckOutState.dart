

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mymenu/Authenticate/Auth.dart';
import 'package:mymenu/Models/ConfirmCheckOut.dart';
import 'package:mymenu/Shared/Database.dart';
import 'package:mymenu/Shared/Price.dart';

class CheckOutState with ChangeNotifier{

  List<ConfirmCheckOut> orders = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final price = Price();



  CheckOutState(){

  }
  List<ConfirmCheckOut> _ordersFromSnapshot(DocumentSnapshot snapshot) {
    snapshot.data.keys.forEach((element) {


      try {


        if(snapshot[element]["inActive"]==1 && snapshot[element]["checkOut"]!="Yes"){


          ConfirmCheckOut confirmCheckOut = ConfirmCheckOut(
              title:snapshot[element]["title"],
              price:snapshot[element]["price"],
              quantity: snapshot[element]["quantity"],
              time: snapshot[element]["date"],
              shop:snapshot[element]["shop"],
              mealOptions: snapshot[element]["selectedOptions"] ?? []

          );

          //log('THOSE OPTIONS ${confirmCheckOut.mealOptions}');
          //print(confirmCheckOut.mealOptions);

          orders.add(confirmCheckOut);
          notifyListeners();


        }
        print(snapshot[element]["shop"]);
      }
      catch(e){
        print(e);
      }
    });

    return orders;

  }

  Future userID() async {
    final FirebaseUser user = await _auth.currentUser();
    return user.uid;
  }


  Stream<List<ConfirmCheckOut>> myOrders(String uid){

    return Firestore.instance.collection("OrdersRefined").document(uid).snapshots().map(_ordersFromSnapshot);
  }

  checkOutApproved(List<ConfirmCheckOut> orders) async{
    for(int i =0;i<orders.length;i++){
      FirebaseAnalytics().logEvent(name: "OrderPlaced",parameters: {
        "title":orders[i].title,
        "price":orders[i].price,
        "shop":orders[i].shop,
        "date":orders[i].time,
        "quantity":orders[i].quantity,
      });
      await Auth().checkOutApproved(orders[i]);
    }
  }

  sendLocation()async{
    Position position = await Geolocator().getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    await Database().loadLocation(position.latitude, position.longitude);
  }

  deleteItem(ConfirmCheckOut order)async{
    await Auth().deleteFromDb(
        order.title);
    notifyListeners();

  }

  double calculateTotal(List<ConfirmCheckOut> ordersSelected){
    try {

      return double.parse(
          (price.calculatePrice(ordersSelected))
              .toStringAsFixed(2));
    }
    catch(e){

    }
  }


}
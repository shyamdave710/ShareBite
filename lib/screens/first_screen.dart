import 'package:flutter/material.dart';
import 'package:share_bite_try1/screens/register_sign_in_screen.dart';
import 'package:share_bite_try1/utils/app_scaffold.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      color: Colors.white,
      // decoration: const BoxDecoration(
      //     gradient: RadialGradient(
      //       radius: 1,
      //       colors: [
      //         Colors.white,
      //         Color.fromRGBO(248, 200, 118, 1.0),
      //       ],)
      // ),
      child: AppScaffold(
        title: "ShareBite",
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              flex: 2,
              child: SizedBox(
                height: double.infinity,
                child: Column(
                  children: [
                    SizedBox(
                      height: size.height*0.085,
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                      child: Image.asset(
                        "assets/images/logo.png",
                        alignment: Alignment.center,
                        height: size.height*0.25,
                        width: size.width*0.8,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Image.asset(
                      "assets/images/img4.jpg",
                      alignment: Alignment.center,
                      height: size.height*0.25,
                      width: size.width*0.8,
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 1,
              child: Center(
                child: ElevatedButton(
                  onPressed: (){
                    showModalBottomSheet(
                      backgroundColor: Colors.white,
                      showDragHandle: true,
                      barrierColor: Colors.black.withOpacity(0.9),
                      elevation: 25,
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                      ),
                      builder: (BuildContext context) {
                        return SizedBox(
                          height: 300,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(35.0),
                              child: Column(
                                children: [
                                  const Text(
                                    "You can register as any of following",
                                    style: TextStyle(
                                        color: Color.fromRGBO(57, 81, 68, 1.0),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24
                                    ),),
                                  const SizedBox(
                                    height: 25,
                                  ),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton(onPressed: () {
                                          debugPrint("1st Clicked..!!");
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterSignUp(role: "Donor"),));
                                        },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color.fromRGBO(57, 81, 68, 1.0),
                                            foregroundColor: Colors.white,
                                            elevation: 25,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            shadowColor: Colors.black,
                                            padding: const EdgeInsets.all(15),
                                          ),
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children:[
                                              Icon(Icons.fastfood_outlined),
                                              SizedBox(height: 5),
                                              Text("\nDonors", textAlign: TextAlign.center,),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        ElevatedButton(onPressed: () {
                                          debugPrint("2nd Clicked..!!");
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterSignUp(role: "NGO"),));
                                        },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color.fromRGBO(57, 81, 68, 1.0),
                                            // backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            elevation: 25,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            shadowColor: Colors.black,
                                            padding: const EdgeInsets.all(15),
                                          ),
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children:[
                                              Icon(Icons.account_balance_outlined),
                                              SizedBox(height: 5),
                                              Text("\nNGOs",textAlign: TextAlign.center),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        ElevatedButton(onPressed: () {
                                          debugPrint("3rd Clicked..!!");
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterSignUp(role: "Delivery Partner"),));
                                        },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color.fromRGBO(57, 81, 68, 1.0),
                                            // backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            elevation: 25,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            shadowColor: Colors.black,
                                            padding: const EdgeInsets.all(15),
                                          ),
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children:[
                                              Icon(Icons.directions_bike_outlined),
                                              SizedBox(height: 5),
                                              Text("Delivery\n Man",textAlign: TextAlign.center),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(57, 81, 68, 1.0),
                    elevation: 15,
                    side: const BorderSide(color: Color.fromRGBO(57, 81, 68, 1.0), width: 2),
                    shadowColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(15),
                  ),
                  child:  const Text("Register Your Self",style: TextStyle(color: Colors.white, fontSize: 28),),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



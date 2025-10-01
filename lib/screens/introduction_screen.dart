import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:share_bite_try1/screens/first_screen.dart';

class IntroductionPage extends StatelessWidget {
  const IntroductionPage({Key? key}) : super(key: key);

  void _onIntroEnd(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      globalBackgroundColor: Colors.black, // prevents black bars
      pages: [
        PageViewModel(
          titleWidget: const SizedBox.shrink(),
          bodyWidget: const SizedBox.shrink(),
          image: _buildFullScreenImagePage(
            context,
            imagePath: 'assets/images/intr2.jpg',
            title: '🌍 Reduce Food Waste',
            body:
            'Everyday, tons of food go to waste. ShareBite connects communities to ensure surplus food reaches those in need — not the landfill.',
          ),
          decoration: const PageDecoration(
            imageFlex: 1,
            bodyFlex: 0,
            fullScreen: true,
            pageColor: Colors.transparent,
          ),
        ),
        PageViewModel(
          titleWidget: const SizedBox.shrink(),
          bodyWidget: const SizedBox.shrink(),
          image: _buildFullScreenImagePage(
            context,
            imagePath: 'assets/images/intr3.jpg',
            title: '🤝 Connect & Share',
            body:
            'Whether you’re a restaurant or organization, ShareBite lets you easily donate or request food through a safe, trusted platform.',
          ),
          decoration: const PageDecoration(
            imageFlex: 1,
            bodyFlex: 0,
            fullScreen: true,
            pageColor: Colors.transparent,
          ),
        ),
        PageViewModel(
          titleWidget: const SizedBox.shrink(),
          bodyWidget: const SizedBox.shrink(),
          image: _buildFullScreenImagePage(
            context,
            imagePath: 'assets/images/intr1.jpg',
            title: '🚀 Get Started with ShareBite',
            body:
            'Become part of a growing network that cares. Sign up now and start making a difference — one meal at a time.',
          ),
          decoration: const PageDecoration(
            imageFlex: 1,
            bodyFlex: 0,
            fullScreen: true,
            pageColor: Colors.transparent,
          ),
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),
      showSkipButton: true,
      skip: const Text('Skip'),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
      curve: Curves.fastLinearToSlowEaseIn,
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      dotsContainerDecorator: const ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
    );
  }

  Widget _buildFullScreenImagePage(
      BuildContext context, {
        required String imagePath,
        required String title,
        required String body,
      }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black87,
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              body,
              style: const TextStyle(
                fontSize: 18.0,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

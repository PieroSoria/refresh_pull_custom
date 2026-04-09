import 'package:flutter/material.dart';

class UpdateRefresh extends StatelessWidget {
  const UpdateRefresh({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: MediaQuery.of(context).size.width / 2.75,
      right: MediaQuery.of(context).size.width / 2.75,
      bottom: 8,
      child: Container(
        width: 104,
        height: 36,
        padding: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: Colors.deepPurpleAccent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.arrow_upward_outlined,
              size: 18,
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: List.generate(
                  3,
                  (index) => Positioned(
                    left: index * 22,
                    child: Container(
                      width: 35,
                      height: 35,
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepPurpleAccent,
                      ),
                      child: Image.asset(
                        'assets/image/photo.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

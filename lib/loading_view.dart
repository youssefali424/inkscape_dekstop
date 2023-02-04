import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  final double? loadingPercentage;
  final bool? isLoadingFonts;
  const LoadingView({
    Key? key,
    this.loadingPercentage,
    this.isLoadingFonts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoadingFonts ?? false) {
      return Positioned.fill(
          child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.5),
              child: Center(
                  child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 24),
                    Text(
                      'Creating font...',
                      style: TextStyle(
                        fontSize: 20,
                        // color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ))));
    }
    return Positioned.fill(
        child: loadingPercentage != null
            ? Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.5),
                child: Center(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LinearProgressIndicator(value: loadingPercentage),
                )))
            : const SizedBox.shrink());
  }
}

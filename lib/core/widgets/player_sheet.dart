import 'package:flutter/material.dart';

/// Shared mobile presentation with room for system navigation and large text.
Future<T?> showPlayerSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: Duration(milliseconds: 320),
              reverseDuration: Duration(milliseconds: 240),
            ),
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .8,
          child: builder(context),
        ),
      ),
    );

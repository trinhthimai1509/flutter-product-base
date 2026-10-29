import 'package:flutter/material.dart';

import 'onboarding_controller.dart';

/// One onboarding page. Content is the product's; the package ships none.
class OnboardingPage {
  const OnboardingPage({
    required this.title,
    required this.description,
    this.illustration,
  });

  final String title;
  final String description;
  final Widget? illustration;
}

/// Button and indicator texts. Defaults are English; pass localized values
/// from the app.
class OnboardingLabels {
  const OnboardingLabels({
    this.skip = 'Skip',
    this.next = 'Next',
    this.finish = 'Get started',
    this.pageIndicator = _defaultIndicator,
  });

  final String skip;
  final String next;
  final String finish;

  /// Semantics label for the dots, e.g. "Page 2 of 3".
  final String Function(int current, int total) pageIndicator;

  static String _defaultIndicator(int current, int total) =>
      'Page $current of $total';
}

/// Full-screen pager with skip, page dots and next/finish.
class OnboardingView extends StatefulWidget {
  const OnboardingView({
    super.key,
    required this.pages,
    required this.controller,
    this.labels = const OnboardingLabels(),
  }) : assert(pages.length > 0, 'At least one page is required');

  final List<OnboardingPage> pages;
  final OnboardingController controller;
  final OnboardingLabels labels;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late final PageController _pageController = PageController(
    initialPage: widget.controller.pageIndex,
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncPage);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncPage);
    _pageController.dispose();
    super.dispose();
  }

  void _syncPage() {
    if (!_pageController.hasClients) return;
    final target = widget.controller.pageIndex;
    if (_pageController.page?.round() != target) {
      _pageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = widget.pages;
    final labels = widget.labels;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final index = widget.controller.pageIndex;
        final isLast = index == pages.length - 1;
        return SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Visibility(
                    visible: !isLast,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton(
                      onPressed: widget.controller.skip,
                      child: Text(labels.skip),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: widget.controller.goToPage,
                  itemBuilder: (context, i) => _PageBody(page: pages[i]),
                ),
              ),
              Semantics(
                label: labels.pageIndicator(index + 1, pages.length),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == index
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => widget.controller.next(pages.length),
                    child: Text(isLast ? labels.finish : labels.next),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.page});

  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        children: [
          if (page.illustration != null) ...[
            page.illustration!,
            const SizedBox(height: 32),
          ],
          Text(
            page.title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            page.description,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

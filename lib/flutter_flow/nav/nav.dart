import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../flutter_flow_theme.dart';
import '../../index.dart';
export 'package:go_router/go_router.dart';

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';
import 'package:page_transition/page_transition.dart';
import 'package:luna_kraft/app_state.dart';
import '/backend/schema/structs/index.dart';
import '/auth/firebase_auth/firebase_user_provider.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/auth/two_factor_verification.dart';
import '/onboarding/onboarding_manager.dart';
import '/onboarding/onboarding_screen.dart';

import '/auth/base_auth_user_provider.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

import '/signreg/signin/signin_widget.dart';
import '/signreg/forgot_password/forgot_password_widget.dart';
import '/signreg/profile_input/profile_input_widget.dart';
import '/home/home_page/home_page_widget.dart';
import '/search/explore/explore_widget.dart';
import '/add_post/dream_entry_selection/dream_entry_selection_widget.dart';
import '/add_post/add_post1/add_post1_widget.dart';
import '/add_post/add_post2/add_post2_widget.dart';
import '/add_post4/add_post4_widget.dart';
import '/notificationpage/notificationpage_widget.dart';
import '/profile/prof1/prof1_widget.dart';
import '/add_post/create_post/create_post_widget.dart';
import '/pendingfollows/pendingfollows_widget.dart';
import '/profile/edit_profile/edit_profile_widget.dart';
import '/home/detailedpost/detailedpost_widget.dart';
import '/search/userpage/userpage_widget.dart';
import '/add_post/edit_page/edit_page_widget.dart';
import '/profile/blockedusers/blockedusers_widget.dart';
import '/profile/saved_posts/saved_posts_widget.dart';
import '/membership_page/membership_page_widget.dart';
import '/dream_analysis/analysis/analysis_widget.dart';
import '/settings/settings_page.dart';
import '/settings/two_factor_setup.dart';
import '/main.dart';
import '/dream_analysis/analysis/dream_analysis_page.dart';
import '/examples/transitions_demo_page.dart';
import '/examples/second_page.dart';
import '/zen_mode/zen_mode_page.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lat_lng.dart';
import '../place.dart';

enum ParamType {
  int,
  double,
  String,
  bool,
  DateTime,
  DateTimeRange,
  DocumentReference,
}

String? serializeParam(
  dynamic param,
  ParamType paramType, {
  bool isList = false,
}) {
  try {
    if (param == null) {
      return null;
    }
    if (isList) {
      final serializedValues = (param as Iterable)
          .map((p) => serializeParam(p, paramType, isList: false))
          .where((p) => p != null)
          .toList();
      return jsonEncode(serializedValues);
    }
    switch (paramType) {
      case ParamType.int:
        return param.toString();
      case ParamType.double:
        return param.toString();
      case ParamType.String:
        return param;
      case ParamType.bool:
        return param ? 'true' : 'false';
      case ParamType.DateTime:
        final dateTime = param as DateTime;
        return dateTime.millisecondsSinceEpoch.toString();
      case ParamType.DateTimeRange:
        final dateTimeRange = param as DateTimeRange;
        return jsonEncode({
          'start': dateTimeRange.start.millisecondsSinceEpoch,
          'end': dateTimeRange.end.millisecondsSinceEpoch,
        });
      case ParamType.DocumentReference:
        final reference = param as DocumentReference;
        return reference.path;
      default:
        return null;
    }
  } catch (e) {
    print('Error serializing parameter: $e');
    return null;
  }
}

dynamic deserializeParam<T>(
  String? param,
  ParamType paramType,
  bool isList, {
  List<String>? collectionNamePath,
}) {
  try {
    if (param == null) {
      return null;
    }
    if (isList) {
      final paramValues = jsonDecode(param) as Iterable;
      if (paramValues.isEmpty) {
        return [];
      }
      return paramValues
          .map((p) => deserializeParam<T>(
                p,
                paramType,
                false,
                collectionNamePath: collectionNamePath,
              ))
          .where((p) => p != null)
          .map((p) => p as T)
          .toList();
    }
    switch (paramType) {
      case ParamType.int:
        return int.tryParse(param);
      case ParamType.double:
        return double.tryParse(param);
      case ParamType.String:
        return param;
      case ParamType.bool:
        return param == 'true';
      case ParamType.DateTime:
        final milliseconds = int.tryParse(param);
        return milliseconds != null
            ? DateTime.fromMillisecondsSinceEpoch(milliseconds)
            : null;
      case ParamType.DateTimeRange:
        final dateTimeRangeMap = jsonDecode(param) as Map<String, dynamic>;
        return DateTimeRange(
          start: DateTime.fromMillisecondsSinceEpoch(
              dateTimeRangeMap['start'] as int),
          end: DateTime.fromMillisecondsSinceEpoch(
              dateTimeRangeMap['end'] as int),
        );
      case ParamType.DocumentReference:
        return FirebaseFirestore.instance.doc(param);
      default:
        return null;
    }
  } catch (e) {
    print('Error deserializing parameter: $e');
    return null;
  }
}

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier, [Widget? entryPage]) =>
    GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      redirect: (_, GoRouterState state) async {
        if (state.matchedLocation == '/show-onboarding') {
          // Don't redirect if already going to onboarding
          return null;
        }

        if (appStateNotifier.loggedIn) {
          // Don't redirect if going to profile input
          if (state.matchedLocation == ProfileInputWidget.routePath) {
            return null;
          }

          // Check if user has completed profile setup
          final hasCompletedProfile = await checkUserProfileExists();

          if (!hasCompletedProfile) {
            // User is logged in but hasn't completed profile setup

            // Check if this is a new user who needs onboarding
            try {
              final isNewUser = await OnboardingManager.isNewUser();
              final hasCompletedOnboarding =
                  await OnboardingManager.hasCompletedOnboarding();

              // Only show onboarding to new users who haven't completed it yet
              if (isNewUser && !hasCompletedOnboarding) {
                // Redirect to a temporary route that will show onboarding
                print('Redirecting to onboarding for new user');
                return '/show-onboarding';
              }
            } catch (e) {
              print('Error checking onboarding status: $e');
            }

            // Only redirect to profile input if they don't have a profile
            print(
                'Redirecting to profile input - user needs to complete profile');
            return ProfileInputWidget.routePath;
          } else {
            // If they have a complete profile, mark profile setup as complete
            await OnboardingManager.markProfileSetupComplete();

            // For existing users with profiles, skip onboarding and mark as not new
            final isNewUser = await OnboardingManager.isNewUser();
            final hasCompletedOnboarding =
                await OnboardingManager.hasCompletedOnboarding();

            if (isNewUser) {
              // If they have a profile but are marked as new, correct this
              await OnboardingManager.markUserAsNotNew();
              print('User with complete profile marked as not new');
            }

            if (!hasCompletedOnboarding) {
              // Returning users should skip onboarding and mark it as complete
              await OnboardingManager.markOnboardingComplete();
              print('Existing user with profile - skipping onboarding');
            }
          }

          // Returning users with completed profiles don't need to see onboarding again
        } else {
          // If user is not logged in, make sure they're not being directed
          // to the profile input page or onboarding page
          if (state.matchedLocation == ProfileInputWidget.routePath ||
              state.matchedLocation == '/show-onboarding') {
            // Redirect unauthenticated users to the signin page
            return SigninWidget.routePath;
          }
        }
        return null;
      },
      errorBuilder: (context, state) => appStateNotifier.loggedIn
          ? entryPage ?? NavBarPage()
          : SigninWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => appStateNotifier.loggedIn
              ? entryPage ?? NavBarPage()
              : SigninWidget(),
        ),
        // Add a special route for showing onboarding
        FFRoute(
          name: 'ShowOnboarding',
          path: '/show-onboarding',
          builder: (context, _) => OnboardingScreen(
            onComplete: () async {
              // When onboarding is complete, mark it as such
              await OnboardingManager.markOnboardingComplete();

              // Explicitly mark the user as not new
              await OnboardingManager.markUserAsNotNew();
              print('User marked as not new after completing onboarding');

              // Re-enable auth navigation for future events
              AppStateNotifier.instance.updateNotifyOnAuthChange(true);

              // Go to home page since profile input is already completed
              context.goNamed(HomePageWidget.routeName);
            },
          ),
        ),
        FFRoute(
          name: SigninWidget.routeName,
          path: SigninWidget.routePath,
          builder: (context, params) => SigninWidget(),
        ),
        FFRoute(
          name: TwoFactorVerificationPage.routeName,
          path: TwoFactorVerificationPage.routePath,
          builder: (context, params) => TwoFactorVerificationPage(
            email: params.getParam('email', ParamType.String),
          ),
        ),
        FFRoute(
          name: ForgotPasswordWidget.routeName,
          path: ForgotPasswordWidget.routePath,
          builder: (context, params) => ForgotPasswordWidget(),
        ),
        FFRoute(
          name: ProfileInputWidget.routeName,
          path: ProfileInputWidget.routePath,
          builder: (context, params) => ProfileInputWidget(),
        ),
        FFRoute(
          name: HomePageWidget.routeName,
          path: HomePageWidget.routePath,
          requireAuth: true,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'HomePage')
              : NavBarPage(
                  initialPage: 'HomePage',
                  page: HomePageWidget(),
                ),
        ),
        FFRoute(
          name: DreamEntrySelectionWidget.routeName,
          path: DreamEntrySelectionWidget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'DreamEntrySelection')
              : NavBarPage(
                  initialPage: 'DreamEntrySelection',
                  page: DreamEntrySelectionWidget(),
                ),
        ),
        FFRoute(
          name: AddPost1Widget.routeName,
          path: AddPost1Widget.routePath,
          builder: (context, params) => AddPost1Widget(),
        ),
        FFRoute(
          name: AddPost2Widget.routeName,
          path: AddPost2Widget.routePath,
          builder: (context, params) => AddPost2Widget(
            generatedText: params.getParam(
              'generatedText',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: CreatePostWidget.routeName,
          path: CreatePostWidget.routePath,
          builder: (context, params) => CreatePostWidget(
            generatedText: params.getParam(
              'generatedText',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: AddPost4Widget.routeName,
          path: AddPost4Widget.routePath,
          builder: (context, params) => AddPost4Widget(),
        ),
        FFRoute(
          name: Prof1Widget.routeName,
          path: Prof1Widget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'prof1')
              : NavBarPage(
                  initialPage: 'prof1',
                  page: Prof1Widget(),
                ),
        ),
        FFRoute(
          name: DetailedpostWidget.routeName,
          path: DetailedpostWidget.routePath,
          builder: (context, params) => DetailedpostWidget(
            docref: params.getParam(
              'docref',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['posts'],
            ),
            userref: params.getParam(
              'userref',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['User'],
            ),
            showComments: params.getParam(
              'showComments',
              ParamType.bool,
            ),
          ),
        ),
        FFRoute(
          name: ExploreWidget.routeName,
          path: ExploreWidget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'Explore')
              : NavBarPage(
                  initialPage: 'Explore',
                  page: ExploreWidget(),
                ),
        ),
        FFRoute(
          name: UserpageWidget.routeName,
          path: UserpageWidget.routePath,
          builder: (context, params) => UserpageWidget(
            profileparameter: params.getParam(
              'profileparameter',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['User'],
            ),
          ),
        ),
        FFRoute(
          name: EditPageWidget.routeName,
          path: EditPageWidget.routePath,
          builder: (context, params) => EditPageWidget(
            postPara: params.getParam(
              'postPara',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['posts'],
            ),
          ),
        ),
        FFRoute(
          name: BlockedusersWidget.routeName,
          path: BlockedusersWidget.routePath,
          builder: (context, params) => BlockedusersWidget(
            userref: params.getParam(
              'userref',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['User'],
            ),
          ),
        ),
        FFRoute(
          name: SavedPostsWidget.routeName,
          path: SavedPostsWidget.routePath,
          builder: (context, params) => SavedPostsWidget(),
        ),
        FFRoute(
          name: NotificationpageWidget.routeName,
          path: NotificationpageWidget.routePath,
          builder: (context, params) => NotificationpageWidget(),
        ),
        FFRoute(
          name: MembershipPageWidget.routeName,
          path: MembershipPageWidget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'MembershipPage')
              : NavBarPage(
                  initialPage: 'MembershipPage',
                  page: MembershipPageWidget(),
                ),
        ),
        FFRoute(
          name: AnalysisWidget.routeName,
          path: AnalysisWidget.routePath,
          builder: (context, params) => AnalysisWidget(),
        ),
        FFRoute(
          name: PendingfollowsWidget.routeName,
          path: PendingfollowsWidget.routePath,
          builder: (context, params) => PendingfollowsWidget(),
        ),
        FFRoute(
          name: SettingsPage.routeName,
          path: SettingsPage.routePath,
          builder: (context, params) => SettingsPage(),
        ),
        FFRoute(
          name: TwoFactorSetupPage.routeName,
          path: TwoFactorSetupPage.routePath,
          builder: (context, params) => TwoFactorSetupPage(),
        ),
        FFRoute(
          name: EditProfileWidget.routeName,
          path: EditProfileWidget.routePath,
          builder: (context, params) => EditProfileWidget(),
        ),
        FFRoute(
          name: DreamAnalysisPage.routeName,
          path: DreamAnalysisPage.routePath,
          builder: (context, params) => const DreamAnalysisPage(),
        ),
        FFRoute(
          name: 'zen-mode',
          path: '/zen-mode',
          builder: (context, params) => const ZenModePage(),
        ),
        FFRoute(
          name: 'transitions-demo',
          path: '/transitions-demo',
          builder: (context, params) => const TransitionsDemoPage(),
        ),
        FFRoute(
          name: SecondPage.routeName,
          path: SecondPage.routePath,
          builder: (context, params) => SecondPage(
            title: params.getParam('title', ParamType.String) ?? 'Second Page',
          ),
        ),
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }

  void pushNamedWithFade(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    // Create the transition info
    final transitionInfo = TransitionInfo(
      hasTransition: true,
      transitionType: PageTransitionType.fade,
      duration: duration,
    );

    // Add the transition info to the extra data
    final Map<String, dynamic> extraData =
        extra != null ? (extra as Map<String, dynamic>) : <String, dynamic>{};

    extraData[kTransitionInfoKey] = transitionInfo;

    // Navigate using the Go Router
    pushNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extraData,
    );
  }

  void pushNamedWithScale(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    Duration duration = const Duration(milliseconds: 350),
    Alignment alignment = Alignment.center,
  }) {
    // Create the transition info
    final transitionInfo = TransitionInfo(
      hasTransition: true,
      transitionType: PageTransitionType.scale,
      duration: duration,
      alignment: alignment,
    );

    // Add the transition info to the extra data
    final Map<String, dynamic> extraData =
        extra != null ? (extra as Map<String, dynamic>) : <String, dynamic>{};

    extraData[kTransitionInfoKey] = transitionInfo;

    // Navigate using the Go Router
    pushNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extraData,
    );
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/signin';
          }

          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = appStateNotifier.loading
              ? Center(
                  child: SizedBox(
                    width: 50.0,
                    height: 50.0,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                )
              : page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(key: state.pageKey, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(
        hasTransition: true,
        transitionType: PageTransitionType.fade,
        duration: const Duration(milliseconds: 300),
      );
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}

class NavBarPage extends StatefulWidget {
  NavBarPage({Key? key, this.initialPage, this.page}) : super(key: key);

  final String? initialPage;
  final Widget? page;

  @override
  _NavBarPageState createState() => _NavBarPageState();
}

class _NavBarPageState extends State<NavBarPage>
    with SingleTickerProviderStateMixin {
  String _currentPageName = 'HomePage';
  late Widget? _currentPage;
  int _selectedIndex = 0;
  late AnimationController _controller;
  Animation<double>? _positionAnimation;
  Animation<double>? _scaleAnimation;
  Animation<double>? _rotationAnimation;
  double _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
    _selectedIndex = _getInitialIndex();
    _previousIndex = _selectedIndex.toDouble();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _setupAnimations();

    _controller.addListener(() {
      setState(() {});
    });
  }

  void _setupAnimations() {
    _positionAnimation = Tween<double>(
      begin: _previousIndex,
      end: _selectedIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0),
        weight: 60,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0.1),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: -0.1),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.1, end: 0),
        weight: 30,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _getInitialIndex() {
    final tabs = {
      'HomePage': 0,
      'Explore': 1,
      'DreamEntrySelection': 2,
      'MembershipPage': 3,
      'prof1': 4,
    };
    return tabs[_currentPageName] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = {
      'HomePage': HomePageWidget(),
      'Explore': ExploreWidget(),
      'DreamEntrySelection': DreamEntrySelectionWidget(),
      'MembershipPage': MembershipPageWidget(),
      'prof1': Prof1Widget(),
    };

    return Scaffold(
      body: _currentPage ?? tabs[_currentPageName],
      extendBody: true,
      bottomNavigationBar: Container(
        height: 75,
        margin: EdgeInsets.only(left: 12, right: 12, bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.light
                  ? FlutterFlowTheme.of(context).primary.withOpacity(0.1)
                  : FlutterFlowTheme.of(context).primary.withOpacity(0.2),
              blurRadius:
                  Theme.of(context).brightness == Brightness.light ? 15 : 30,
              spreadRadius:
                  Theme.of(context).brightness == Brightness.light ? 0 : 1,
              offset: Offset(
                  0, Theme.of(context).brightness == Brightness.light ? 5 : 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.light
                      ? [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.85),
                        ]
                      : [
                          FlutterFlowTheme.of(context)
                              .secondaryBackground
                              .withOpacity(0.7),
                          FlutterFlowTheme.of(context)
                              .secondaryBackground
                              .withOpacity(0.3),
                        ],
                ),
                border: Border.all(
                  width: 1.5,
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(
                children: [
                  // Animated particles effect
                  ..._buildParticles(context),

                  // Background glow effect for selected item
                  AnimatedPositioned(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    left: (_positionAnimation?.value ?? _selectedIndex) *
                        (MediaQuery.of(context).size.width - 24) /
                        5,
                    top: 0,
                    bottom: 0,
                    width: (MediaQuery.of(context).size.width - 24) / 5,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.8,
                          colors:
                              Theme.of(context).brightness == Brightness.light
                                  ? [
                                      FlutterFlowTheme.of(context)
                                          .primary
                                          .withOpacity(0.06),
                                      Colors.transparent,
                                    ]
                                  : [
                                      FlutterFlowTheme.of(context)
                                          .primary
                                          .withOpacity(0.2),
                                      Colors.transparent,
                                    ],
                        ),
                      ),
                    ),
                  ),

                  // Navigation items with indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItemWithIndicator(0, Icons.home_outlined,
                          Icons.home_rounded, 'Home', 'HomePage'),
                      _buildNavItemWithIndicator(1, Icons.search_outlined,
                          Icons.search_rounded, 'Explore', 'Explore'),
                      _buildNavItemWithIndicator(
                          2,
                          Icons.add_circle_outline_rounded,
                          Icons.add_circle_rounded,
                          'Add',
                          'DreamEntrySelection'),
                      _buildNavItemWithIndicator(3, Icons.diamond_outlined,
                          Icons.diamond_rounded, 'Premium', 'MembershipPage'),
                      _buildNavItemWithIndicator(
                          4,
                          Icons.person_outline_rounded,
                          Icons.person_rounded,
                          'Profile',
                          'prof1'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Generate animated particles for background effect
  List<Widget> _buildParticles(BuildContext context) {
    final random = Random();
    final width = MediaQuery.of(context).size.width -
        72; // Adjust width to prevent overflow
    return List.generate(
      6, // Reduce number of particles
      (index) => Positioned(
        left: random.nextDouble() * width + 16, // Ensure within safe margins
        top: random.nextDouble() * 50,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final animation = Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  index / 10,
                  (index + 5) / 10,
                  curve: Curves.easeInOut,
                ),
              ),
            );

            return Container(
              width: 3 + (index % 3) * 1.5, // Slightly smaller particles
              height: 3 + (index % 3) * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FlutterFlowTheme.of(context).primary.withOpacity(
                      Theme.of(context).brightness == Brightness.light
                          ? (0.03 +
                              0.03 *
                                  animation
                                      .value) // Much lighter for light mode
                          : (0.1 + 0.1 * animation.value),
                    ),
                boxShadow: [
                  BoxShadow(
                    color: FlutterFlowTheme.of(context).primary.withOpacity(
                          Theme.of(context).brightness == Brightness.light
                              ? 0.1 // Reduced shadow for light mode
                              : 0.3,
                        ),
                    blurRadius: 3 + animation.value, // Smaller blur
                    spreadRadius: -1,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItemWithIndicator(int index, IconData unselectedIcon,
      IconData selectedIcon, String label, String pageName) {
    final isSelected = _selectedIndex == index;
    final isAnimating =
        _positionAnimation?.value.round() == index && _controller.isAnimating;

    // Special sizing for the Add button (index 2)
    final double selectedSize = index == 2 ? 40 : 35;
    final double unselectedSize = index == 2 ? 35 : 30;

    return Flexible(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _previousIndex = _selectedIndex.toDouble();
            _selectedIndex = index;
            _currentPage = null;
            _currentPageName = pageName;
            _setupAnimations();
          });
          _controller.forward(from: 0);

          // Add haptic feedback
          HapticFeedback.lightImpact();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon with transform effects
            Transform.scale(
              scale: isSelected || isAnimating
                  ? (_scaleAnimation?.value ?? 1.0)
                  : 1.0,
              child: Transform.rotate(
                angle: isSelected || isAnimating
                    ? (_rotationAnimation?.value ?? 0) * 3.14
                    : 0,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 200),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey<bool>(isSelected),
                    padding: EdgeInsets.all(4),
                    decoration: isSelected
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                FlutterFlowTheme.of(context)
                                    .primary
                                    .withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          )
                        : null,
                    child: Icon(
                      isSelected ? selectedIcon : unselectedIcon,
                      color: isSelected
                          ? FlutterFlowTheme.of(context).primary
                          : FlutterFlowTheme.of(context)
                              .secondaryText
                              .withOpacity(0.7),
                      size: isSelected ? selectedSize : unselectedSize,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 2),
            // Label with fade animation
            AnimatedOpacity(
              duration: Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.7,
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      fontFamily: 'Figtree',
                      color: isSelected
                          ? FlutterFlowTheme.of(context).primary
                          : FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ),
            // Direct indicator under each item
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: 3,
              width: isSelected ? 36 : 0,
              margin: EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FlutterFlowTheme.of(context).primary.withOpacity(0.8),
                    FlutterFlowTheme.of(context).secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: -2,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

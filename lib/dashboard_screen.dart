import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/theme.dart';
import 'package:flutter_login/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sijempol_manise/constants.dart';
import 'package:sijempol_manise/transition_route_observer.dart';
import 'package:sijempol_manise/widgets/fade_in.dart';
import 'package:sijempol_manise/widgets/round_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';

  const DashboardScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, TransitionRouteAware {
  Future<bool> _goToLogin(BuildContext context) async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    pref.remove('jwt');
    pref.remove('is_login');

    return Navigator.of(context)
        .pushReplacementNamed('/auth')
        // we dont want to pop the screen, just replace it completely
        .then((_) => false);
  }

  final routeObserver = TransitionRouteObserver<PageRoute?>();
  static const headerAniInterval = Interval(.1, .3, curve: Curves.easeOut);
  late Animation<double> _headerScaleAnimation;
  AnimationController? _loadingController;

  String nama = '';
  String level = '';
  String jumlahPaket = '0';
  String paketBerjalan = '0';
  String paketSelesai = '0';

  @override
  void initState() {
    super.initState();

    _getDashboardData();

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );

    _headerScaleAnimation = Tween<double>(begin: .6, end: 1).animate(
      CurvedAnimation(
        parent: _loadingController!,
        curve: headerAniInterval,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(
      this,
      ModalRoute.of(context) as PageRoute<dynamic>?,
    );
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _loadingController!.dispose();
    super.dispose();
  }

  @override
  void didPushAfterTransition() => _loadingController!.forward();

  Future _getDashboardData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    String? jwt = prefs.getString('jwt');

    final response = await http.get(
      Uri.parse(Constants.dashboardUrl),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': ('Bearer ') + jwt.toString(),
      },
    );

    if (200 == response.statusCode) {
      Map<String, dynamic> result = jsonDecode(response.body);

      setState(() {
        nama = result['user']['nama'];
        level = result['user']['level']['name'];
        jumlahPaket = result['jumlah_paket'].toString();
        paketBerjalan = result['paket_berjalan'].toString();
        paketSelesai = result['paket_selesai'].toString();
      });
    }
  }

  AppBar _buildAppBar(ThemeData theme) {
    final signOutBtn = IconButton(
      icon: const Icon(FontAwesomeIcons.rightFromBracket),
      color: theme.colorScheme.secondary,
      onPressed: () => _goToLogin(context),
    );
    final title = Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Hero(
              tag: Constants.logoTag,
              child: Image.asset(
                'assets/logo.png',
                filterQuality: FilterQuality.high,
                height: 30,
              ),
            ),
          ),
          const SizedBox(width: 10),
          HeroText(
            Constants.appName,
            tag: Constants.titleTag,
            viewState: ViewState.shrunk,
            style: LoginThemeHelper.loginTextStyle!.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );

    return AppBar(
      actions: <Widget>[
        FadeIn(
          controller: _loadingController,
          offset: .3,
          curve: headerAniInterval,
          fadeDirection: FadeDirection.endToStart,
          child: signOutBtn,
        ),
      ],
      title: title,
      backgroundColor: theme.primaryColor.withOpacity(.1),
      elevation: 0,
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return ScaleTransition(
      scale: _headerScaleAnimation,
      child: FadeIn(
        controller: _loadingController,
        curve: headerAniInterval,
        fadeDirection: FadeDirection.bottomToTop,
        offset: .5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              nama,
              style: theme.textTheme.displaySmall!.copyWith(
                fontWeight: FontWeight.w300,
                color: theme.colorScheme.secondary,
                fontSize: 40,
              ),
            ),
            Text(level, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    Widget? icon,
    String? label,
    required Interval interval,
  }) {
    return RoundButton(
      icon: icon,
      label: label,
      loadingController: _loadingController,
      interval: Interval(
        interval.begin,
        interval.end,
        curve: const ElasticOutCurve(0.42),
      ),
      onPressed: () {
        _getDashboardData();
      },
    );
  }

  Widget _buildDashboardGrid() {
    const step = 0.04;
    const aniInterval = 0.75;

    return GridView.count(
      padding: const EdgeInsets.symmetric(
        horizontal: 32.0,
        vertical: 20,
      ),
      childAspectRatio: .9,
      // crossAxisSpacing: 5,
      crossAxisCount: 3,
      children: [
        _buildButton(
          icon: Text(
            jumlahPaket,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          label: 'Semua Paket',
          interval: const Interval(0, aniInterval),
        ),
        _buildButton(
          icon: Text(
            paketBerjalan,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          label: 'Paket Berjalan',
          interval: const Interval(0, aniInterval),
        ),
        _buildButton(
          icon: Text(
            paketSelesai,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          label: 'Paket Selesai',
          interval: const Interval(0, aniInterval),
        ),
        _buildButton(
          icon: const Icon(FontAwesomeIcons.peopleGroup),
          label: 'Data Penyedia',
          interval: const Interval(0, aniInterval),
        ),
        _buildButton(
          icon: const Icon(FontAwesomeIcons.building),
          label: 'Data OPD',
          interval: const Interval(0, aniInterval),
        ),
        _buildButton(
          icon: const Icon(FontAwesomeIcons.map),
          label: 'Map',
          interval: const Interval(0, aniInterval),
        ),
        _buildButton(
          icon: Container(
            // fix icon is not centered like others for some reasons
            padding: const EdgeInsets.only(left: 16.0),
            alignment: Alignment.centerLeft,
            child: const Icon(
              FontAwesomeIcons.chartLine,
              size: 20,
            ),
          ),
          label: 'Rekapitulasi',
          interval: const Interval(step, aniInterval + step),
        ),
        _buildButton(
          icon: const Icon(FontAwesomeIcons.info),
          label: 'Tentang Aplikasi',
          interval: const Interval(0, aniInterval),
        ),
        _buildButton(
          icon: const Icon(FontAwesomeIcons.sliders),
          label: 'Pengaturan',
          interval: const Interval(0, aniInterval),
        ),
      ],
    );
  }

  Widget _buildDebugButtons() {
    const textStyle = TextStyle(fontSize: 12, color: Colors.white);

    return Positioned(
      bottom: 0,
      right: 0,
      child: Row(
        children: <Widget>[
          MaterialButton(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            color: Colors.red,
            onPressed: () => _loadingController!.value == 0
                ? _loadingController!.forward()
                : _loadingController!.reverse(),
            child: const Text('reload', style: textStyle),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () => _goToLogin(context),
      child: SafeArea(
        child: Scaffold(
          appBar: _buildAppBar(theme),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: theme.primaryColor.withOpacity(.1),
            child: Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    const SizedBox(height: 40),
                    Expanded(
                      flex: 2,
                      child: _buildHeader(theme),
                    ),
                    Expanded(
                      flex: 8,
                      child: ShaderMask(
                        // blendMode: BlendMode.srcOver,
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Colors.deepPurpleAccent.shade100,
                              Colors.deepPurple.shade100,
                              Colors.deepPurple.shade100,
                              Colors.deepPurple.shade100,
                              // Colors.red,
                              // Colors.yellow,
                            ],
                          ).createShader(bounds);
                        },
                        child: _buildDashboardGrid(),
                      ),
                    ),
                  ],
                ),
                if (!kReleaseMode) _buildDebugButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

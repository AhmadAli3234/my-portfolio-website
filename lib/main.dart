import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// --- 1. THEME MANAGEMENT (Provider Setup) ---

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}

// --- 2. MAIN APP AND RESPONSIVE WRAPPER (Renamed to MyApp to match error trace) ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // The ChangeNotifierProvider wraps the root widget (MyApp), ensuring ThemeService is available
    ChangeNotifierProvider(
      create: (context) => ThemeService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Accessing the ThemeService is now safe because MyApp is a descendant of ChangeNotifierProvider
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
      scrollBehavior: ScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
      ),
      title: 'Ahmad Ali | Flutter Developer',
      debugShowCheckedModeBanner: false,
      themeMode: themeService.themeMode,

      // Light Theme
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
          brightness: Brightness.light,
        ).copyWith(secondary: Colors.tealAccent.shade700),
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.grey.shade50,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),

      // Dark Theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue, // Vibrant Blue Accent
          brightness: Brightness.dark,
        ).copyWith(secondary: Colors.blueAccent.shade400),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white60),
          titleLarge: TextStyle(color: Colors.white),
        ),
      ),

      // Responsive Framework setup
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1200, name: DESKTOP),
        ],
      ),
      home: const PortfolioHomePage(),
    );
  }
}

// --- 3. HOMEPAGE AND NAVIGATION (SCROLL) ---

class PortfolioHomePage extends StatefulWidget {
  const PortfolioHomePage({super.key});

  @override
  State<PortfolioHomePage> createState() => _PortfolioHomePageState();
}

class _PortfolioHomePageState extends State<PortfolioHomePage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> sectionKeys = {
    'Home': GlobalKey(),
    'About': GlobalKey(),
    'Projects': GlobalKey(),
    'Skills': GlobalKey(),
    'Contact': GlobalKey(),
  };

  void _scrollToSection(String sectionName) {
    final key = sectionKeys[sectionName];
    if (key != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.0, // Scroll to the top of the target widget
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1000,
            ), // Max width for content
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  SectionWrapper(
                    key: sectionKeys['Home'],
                    child: const IntroSection(),
                  ),
                  SectionDivider(),
                  SectionWrapper(
                    key: sectionKeys['About'],
                    child: const AboutMeSection(),
                  ),
                  SectionDivider(),
                  SectionWrapper(
                    key: sectionKeys['Projects'],
                    child: const ProjectsSection(),
                  ),
                  SectionDivider(),
                  SectionWrapper(
                    key: sectionKeys['Skills'],
                    child: const SkillsSection(),
                  ),
                  SectionDivider(),
                  SectionWrapper(
                    key: sectionKeys['Contact'],
                    child: _SocialLinks(),
                  ),
                  const Footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    // Provider is accessed safely here, as this widget is a descendant of MyApp
    final themeService = Provider.of<ThemeService>(context);

    return AppBar(
      elevation: 0,
      title: FadeInDown(
        duration: const Duration(milliseconds: 600),
        child: Text(
          'Portfolio',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      actions: [
        if (!isMobile) ..._buildDesktopNavButtons(),
        IconButton(
          icon: Icon(
            themeService.themeMode == ThemeMode.light
                ? Icons.dark_mode
                : Icons.light_mode,
          ),
          onPressed: themeService.toggleTheme,
        ),
        if (isMobile)
          Builder(
            // Builder is necessary to get the Scaffold context
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildDesktopNavButtons() {
    return sectionKeys.keys
        .map(
          (name) => TextButton(
            onPressed: () => _scrollToSection(name),
            child: Text(name, style: GoogleFonts.poppins(fontSize: 16)),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// Custom widget to give padding and spacing to sections
class SectionWrapper extends StatelessWidget {
  final Widget child;
  const SectionWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50.0),
      child: child,
    );
  }
}

// Custom divider
class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      child: Divider(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        thickness: 1,
        height: 1,
        indent: 50,
        endIndent: 50,
      ),
    );
  }
}

// --- 4. INTRO SECTION ---

class IntroSection extends StatelessWidget {
  const IntroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 50 : 100),
      child: isMobile
          ? _buildMobileLayout(context)
          : _buildDesktopLayout(context),
    );
  }

  Widget _buildProfilePicture(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return ElasticIn(
      delay: const Duration(milliseconds: 800),
      child: CircleAvatar(
        radius: 120,
        backgroundColor: color.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 20),
            ],
            image: const DecorationImage(
              // IMPORTANT: Replace with your actual profile image asset path
              image: AssetImage('assets/images/profile_pic.jpg'),
              fit: BoxFit.fitHeight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroText(BuildContext context) {
    return FadeInLeft(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Hi, I’m Ahmad Ali',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'A Flutter Developer.',
            style: GoogleFonts.poppins(
              fontSize: ResponsiveBreakpoints.of(context).isDesktop ? 60 : 40,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              _ActionButton(
                text: 'Hire Me',
                isPrimary: true,
                onPressed: () async {
                  final Uri email = Uri(
                    scheme: 'mailto',
                    path: "ahmadalirj99@gmail.com",
                    query:
                        'subject=Hiring Inquiry&body=Hi Ahmad, I found your portfolio and would like to discuss a project with you.',
                  );
                  if (await canLaunchUrl(email)) {
                    await launchUrl(
                      email,
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    throw "Somethning went wrong";
                  }
                },
                icon: Icons.send,
              ),
              const SizedBox(width: 15),
              _ActionButton(
                text: 'Download Cv',
                isPrimary: false,
                onPressed: () async {
                  const String fileId = "1uMDojJWcSRD_Y7MvCtpIvudcw9N68GYk";
                  final Uri downloadUrl = Uri.parse(
                    "https://drive.google.com/uc?export=download&id=$fileId",
                  );

                  try {
                    final bool launched = await launchUrl(
                      downloadUrl,
                      mode: LaunchMode.platformDefault,
                    );

                    if (!launched) {
                      throw Exception('Could not launch URL.');
                    }
                  } catch (e) {
                    debugPrint('Error launching URL: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to open CV. Please try again.'),
                      ),
                    );
                  }
                },

                icon: Icons.download,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _buildIntroText(context)),
        const SizedBox(width: 50),
        _buildProfilePicture(context),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildProfilePicture(context),
        const SizedBox(height: 40),
        _buildIntroText(context),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final bool isPrimary;
  final VoidCallback onPressed;
  final IconData icon;

  const _ActionButton({
    required this.text,
    required this.isPrimary,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;

    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 2),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

// --- 5. ABOUT ME SECTION ---

class AboutMeSection extends StatelessWidget {
  const AboutMeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SlideInLeft(
          child: Text(
            'About Me',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        FadeInUp(
          delay: const Duration(milliseconds: 200),
          child: const Text(
            'I am a passionate cross-platform mobile and web developer specializing in Flutter. My journey started one year ago, focusing on building beautiful, fast, and scalable applications backed by Firebase and REST APIs. I thrive on translating UI/UX designs into pixel-perfect, smooth user interfaces, and I am committed to continuous learning in the rapidly evolving Flutter ecosystem.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: ResponsiveRowColumn(
            layout: ResponsiveBreakpoints.of(context).isMobile
                ? ResponsiveRowColumnType.COLUMN
                : ResponsiveRowColumnType.ROW,
            rowMainAxisAlignment: MainAxisAlignment.spaceBetween,
            rowCrossAxisAlignment: CrossAxisAlignment.stretch,
            columnSpacing: 20,
            rowSpacing: 20,
            children: [
              ResponsiveRowColumnItem(
                child: _HighlightCard(
                  title: '1 Year',
                  subtitle: 'Flutter Experience    ',
                  icon: Icons.calendar_month,
                ),
              ),
              ResponsiveRowColumnItem(
                child: _HighlightCard(
                  title: '10+ Projects',
                  subtitle: 'Completed Portfolio Apps',
                  icon: Icons.app_blocking_sharp,
                ),
              ),
              ResponsiveRowColumnItem(
                child: _HighlightCard(
                  title: 'Cross-Platform',
                  subtitle: 'Mobile, Web, & Desktop',
                  icon: Icons.devices,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HighlightCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 6. PROJECTS SECTION ---

class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  final List<Map<String, String>> projects = const [
    {
      'title': 'Course App UI',
      'desc':
          'A clean and responsive UI that allows users to browse, search, and explore a variety of Course with detail.',
      'github': "https://github.com/AhmadAli3234/courses_ui_app",
      'live': '#',
      'image': 'assets/images/720.png',
    },
    {
      'title': 'Shoes Store App',
      'desc':
          'A clean and responsive UI that allows users to browse, search, and explore a variety of shoes',
      'github': 'https://github.com/AhmadAli3234/shoes_store_app',
      'live': '#',
      'image': 'assets/images/420.png',
    },
    {
      'title': 'Weather App',
      'desc':
          'A responsive weather application consuming a REST API to display forecasts.',
      'github': 'https://github.com/AhmadAli3234/Weather-App',
      'live': '#',
      'image': 'assets/images/weather apps.jpeg',
    },
    {
      'title': 'Car Rental App UI',
      'desc': 'A clean and responsive UI for car rental App.',
      'github': 'https://github.com/AhmadAli3234/car_rental_ui',
      'live': '#',
      'image': 'assets/images/620.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = ResponsiveBreakpoints.of(context).isMobile
        ? 1
        : ResponsiveBreakpoints.of(context).isTablet
        ? 2
        : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SlideInLeft(
          child: Text(
            'Featured Projects',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 30),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: projects.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.0,
            crossAxisSpacing: 30,
            mainAxisSpacing: 30,
          ),
          itemBuilder: (context, index) {
            final project = projects[index];
            return SlideInUp(
              delay: Duration(milliseconds: 100 * index),
              child: _ProjectCard(project: project),
            );
          },
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Map<String, String> project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Project Screenshot Placeholder
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
                // Using NetworkImage for placeholder (replace with AssetImage in real app)
                image: DecorationImage(
                  image: AssetImage(project['image']!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Project Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project['title']!,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project['desc']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ProjectLinkButton(
                        icon: FontAwesomeIcons.github,
                        label: 'Code',
                        url: project['github']!,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectLinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _ProjectLinkButton({
    required this.icon,
    required this.label,
    required this.url,
  });

  // Placeholder function for opening URL
  Future<void> _launchURL(String repolink) async {
    final Uri getrepourl = Uri.parse(repolink);
    if (!await launchUrl(getrepourl, mode: LaunchMode.platformDefault)) {
      throw Exception("Something went Wrong");
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _launchURL(url);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            FaIcon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 7. SKILLS SECTION ---

class SkillsSection extends StatelessWidget {
  const SkillsSection({super.key});

  final List<Map<String, dynamic>> skills = const [
    {
      'name': 'Flutter',
      'proficiency': 0.9,
      'icon': FontAwesomeIcons.mobileScreenButton,
    },
    {
      'name': 'UI/UX Design',
      'proficiency': 0.95,
      'icon': FontAwesomeIcons.palette,
    },
    {'name': 'Firebase', 'proficiency': 0.65, 'icon': FontAwesomeIcons.fire},
    {'name': 'REST API', 'proficiency': 0.65, 'icon': FontAwesomeIcons.server},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SlideInLeft(
          child: Text(
            'My Technical Skills',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 30),
        ResponsiveRowColumn(
          layout: ResponsiveBreakpoints.of(context).isMobile
              ? ResponsiveRowColumnType.COLUMN
              : ResponsiveRowColumnType.ROW,
          rowMainAxisAlignment: MainAxisAlignment.spaceBetween,
          rowCrossAxisAlignment: CrossAxisAlignment.start,
          columnSpacing: 20,
          rowSpacing: 40,
          children: [
            for (final skill in skills)
              ResponsiveRowColumnItem(
                rowFlex: 1,
                child: SlideInRight(
                  delay: Duration(
                    milliseconds: (skills.indexOf(skill) * 100) + 100,
                  ),
                  child: Padding(
                    padding: ResponsiveBreakpoints.of(context).isMobile
                        ? const EdgeInsets.only(bottom: 20.0)
                        : EdgeInsets.zero,
                    child: _SkillIndicator(
                      name: skill['name'] as String,
                      icon: skill['icon'] as IconData,
                      proficiency: skill['proficiency'] as double,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SkillIndicator extends StatelessWidget {
  final String name;
  final IconData icon;
  final double proficiency;

  const _SkillIndicator({
    required this.name,
    required this.icon,
    required this.proficiency,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: ResponsiveBreakpoints.of(context).isMobile ? double.infinity : 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(icon, size: 18, color: accentColor),
              const SizedBox(width: 10),
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(proficiency * 100).toInt()}%',
                style: TextStyle(color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: proficiency,
            minHeight: 8,
            backgroundColor: Theme.of(context).cardColor,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

// --- 8. CONTACT SECTION ---

class _SocialLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect with Me',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 15),
        _SocialButton(
          icon: FontAwesomeIcons.linkedin,
          text: 'LinkedIn',
          url: 'https://www.linkedin.com/in/ahmad-ali-6205a2310/',
        ),
        _SocialButton(
          icon: FontAwesomeIcons.github,
          text: 'GitHub',
          url: 'https://github.com/AhmadAli3234',
        ),

        _SocialButton(
          icon: Icons.mail,
          text: 'Email',
          url: 'mailto:ahmadalirj99@gmail.com',
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final String url;

  const _SocialButton({
    required this.icon,
    required this.text,
    required this.url,
  });

  void _launchURL(String myurl) async {
    final Uri getlink = Uri.parse(myurl);
    if (await launchUrl(getlink, mode: LaunchMode.platformDefault)) {
      throw Exception("Something Went wrong");
    }
    print('Launching Social URL: $url');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextButton.icon(
        onPressed: () {
          _launchURL(url);
        },
        icon: FaIcon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: Text(
          text,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}

// --- 9. FOOTER ---

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text(
        '© ${DateTime.now().year} Ahmad Ali | Built with Flutter',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}

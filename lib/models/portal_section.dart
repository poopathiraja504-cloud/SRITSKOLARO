import 'package:flutter/material.dart';

enum PortalSection {
  academics('Academics', Icons.school_outlined, '/academic-calender'),
  admissions('Admissions', Icons.how_to_reg_outlined, '/admission'),
  placements('Placements', Icons.work_outline, '/placement'),
  about('About Us', Icons.info_outline, '/about'),
  departments('Departments', Icons.account_tree_outlined, '/departments'),
  events('Events', Icons.event_outlined, '/news-events'),
  campusNews('Campus News', Icons.newspaper_outlined, '/news-events'),
  notifications('Notifications', Icons.notifications_none, ''),
  importantLinks('Important Links', Icons.link, '/'),
  contact('Contact Us', Icons.call_outlined, '/contact'),
  attendance('Attendance', Icons.calendar_month_outlined, ''),
  documents('Documents', Icons.folder_outlined, ''),
  profile('Profile', Icons.person_outline, ''),
  settings('Settings', Icons.settings_outlined, '');

  const PortalSection(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;

  bool get isWebsitePage => path.isNotEmpty;

  Uri get uri => Uri.parse('https://www.sritcbe.ac.in$path');

  static const dashboard = [
    academics,
    admissions,
    placements,
    about,
    departments,
    events,
    campusNews,
    notifications,
    importantLinks,
    contact,
    attendance,
    documents,
  ];

  static const navigation = [
    academics,
    admissions,
    placements,
    about,
    departments,
    events,
    campusNews,
    attendance,
    documents,
    settings,
  ];
}

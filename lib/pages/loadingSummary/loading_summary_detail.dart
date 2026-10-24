import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/pages/loading/loading_provider.dart';
import 'package:flutter_application_1/pages/loading/models/coach_detail.dart';
import 'package:flutter_application_1/pages/loading/models/platform_master.dart';
import 'package:flutter_application_1/pages/loading/models/railway_al.dart';
import 'package:flutter_application_1/pages/loading/models/wag_type.dart';
import 'package:flutter_application_1/pages/loadingSummary/loading_provider.dart';
import 'package:flutter_application_1/pages/scanData/scan_data_page.dart';
import 'package:flutter_application_1/pages/splash/splash_provider.dart';
import 'package:flutter_application_1/services/login_api.dart';
import 'package:flutter_application_1/services/train_session.dart';
import 'package:flutter_application_1/widgets/pms_appbar.dart';
import 'package:provider/provider.dart';

class LoadingSummaryDetailPage extends StatefulWidget {
  const LoadingSummaryDetailPage({super.key});

  @override
  State<LoadingSummaryDetailPage> createState() =>
      _LoadingSummaryDetailPageState();
}

class _LoadingSummaryDetailPageState extends State<LoadingSummaryDetailPage> {
  // ---------- Shared design system (single source of truth) ----------
  static const Color _appBarGreen = const Color(0xFF1565C0);
  static const Color _pmsBlue = const Color(0xFF1565C0);
  static const Color _bgLight = const Color(0xFFF5F7F8);
  static const Color _labelGrey = Colors.grey;
  static const Color _valueBlack = const Color(0xFF111111);
  static const Color _hintGrey = Colors.grey;
  static const Color _dividerGrey = const Color(0xFFE8EEF5);

  // Header logo shown in the nav drawer, not the page watermark.
  static const String _irLogoUrl = "https://cris.org.in/img/footer/redlogo.png";

  // GUI-only state (real APIs/model data will be plugged in later)
  String? _platform;
  String? _platformCode;
  String? _insideLocked;
  bool _acceptIcmsWagon = true;
  String? _wagonRlyNo;
  String? _sealToStation;
  String? _nilReason;
  bool _sealed = true;

  // Shown only while "Accept ICMS Wagon" is unticked. The values are never
  // cleared, so they survive a tick / untick / tick round trip.
  String? _coachType;
  String? _ownRailway;
  final TextEditingController _coachNoController = TextEditingController();

  // Shown only while "Sealed" is unticked.
  final TextEditingController _guardNameController = TextEditingController();
  final TextEditingController _guardHqtrController = TextEditingController();

  final TextEditingController _rpfController = TextEditingController();
  final TextEditingController _guardMobileController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  // Hardcoded on the Angular page (multiple="false"): Left / Right / Not Known.
  final List<String> _insideLockedOptions = ['Left', 'Right', 'Not Known'];
  final List<String> _nilOptions = [
    'NO LOADING',
    'NO UNLOADING',
    'NO SLR',
    'THROUGH SEALED',
    'DOOR JAM',
  ];

  @override
  void initState() {
    super.initState();

    // Preload the master lists (API -> local cache) so Platform No., Own
    // Railway and Coach type are ready when the user taps them.
    Future.microtask(() {
      final provider = context.read<LoadingSummaryProvider>();
      provider.loadPlatformMasters();
      provider.loadRailwayMasters();
      provider.loadWagTypeMasters();
    });
  }

  @override
  void dispose() {
    _coachNoController.dispose();
    _guardNameController.dispose();
    _guardHqtrController.dispose();
    _rpfController.dispose();
    _guardMobileController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  // ---------- Actions ----------

  void _onNext() {
    // Wagon-Rly-No. is only on screen while "Accept ICMS Wagon" is ticked, so
    // the required check has to follow the checkbox instead of always
    // demanding wagonNo (otherwise unticking it would block Submit forever).
    if (_acceptIcmsWagon) {
      if (_wagonRlyNo == null || _wagonRlyNo!.isEmpty) {
        _showValidationBanner(" *wagonNo is required!");
        return;
      }
    } else {
      if (_coachType == null || _coachType!.trim().isEmpty) {
        _showValidationBanner(" *coachType is required!");
        return;
      }
      if (_ownRailway == null || _ownRailway!.trim().isEmpty) {
        _showValidationBanner(" *ownRailway is required!");
        return;
      }
      if (_coachNoController.text.trim().isEmpty) {
        _showValidationBanner(" *coachNo is required!");
        return;
      }
    }
    // Guard Mobile No: must be exactly 10 digits, no spaces or separators.
    final mobile = _guardMobileController.text.trim();
    if (mobile.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(mobile)) {
      _showValidationBanner(" *guard mobile no must be 10 digits!");
      return;
    }

    // Valid state -> open the Scan Data screen.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanDataPage()),
    );
  }

  void _showValidationBanner(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: _appBarGreen,
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: const [],
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) messenger.hideCurrentMaterialBanner();
    });
  }

  // Platform No.: use the preloaded master list (provider -> M_PLATFORM).
  Future<void> _openPlatformNoPicker() async {
    if (!mounted) return;
    final provider = context.read<LoadingSummaryProvider>();

    var platforms = provider.platformMasters;
    if (platforms.isEmpty) {
      await _fetchThenPop("Fetching platforms…", provider.loadPlatformMasters);
      if (!mounted) return;
      platforms = provider.platformMasters;
    }

    if (platforms.isEmpty) {
      _toast(
        "Unable to load platform list. "
        "(${provider.platformError.isNotEmpty ? provider.platformError : "no data"})",
      );
      return;
    }

    final picked = await _showMasterPicker<PlatformMaster>(
      title: "Select Platform No.",
      headerIcon: Icons.meeting_room_outlined,
      itemIcon: Icons.meeting_room,
      searchHint: "Search platform…",
      emptyText: "No matching platform",
      items: platforms,
      labelOf: (p) => p.detail,
      selectedLabel: _platformCode == null ? null : _platform,
      selectedValue: _platformCode,
      identityOf: (p) => p.code,
    );
    if (picked == null || !mounted) return;

    // Display shows the platform TEXT, the stored value is the platform CODE
    // (same as the mentor's ion-option value={item.value} text={item.text}).
    setState(() {
      _platform = picked.detail;
      _platformCode = picked.code;
    });
  }

  // Own Railway: M_RLY master (getRailwayAL).
  Future<void> _openOwnRailwayPicker() async {
    if (!mounted) return;
    final provider = context.read<LoadingSummaryProvider>();

    var items = provider.railwayMasters;
    if (items.isEmpty) {
      await _fetchThenPop("Fetching own railway…", provider.loadRailwayMasters);
      if (!mounted) return;
      items = provider.railwayMasters;
    }

    if (items.isEmpty) {
      _toast(
        "Unable to load railway list. "
        "(${provider.railwayError.isNotEmpty ? provider.railwayError : "no data"})",
      );
      return;
    }

    final picked = await _showMasterPicker<RailwayAL>(
      title: "Select Own Railway",
      headerIcon: Icons.train_outlined,
      itemIcon: Icons.train,
      searchHint: "Search railway…",
      emptyText: "No matching railway",
      items: items,
      labelOf: (r) => r.code,
      selectedLabel: _ownRailway,
      confirmLabel: "OK",
    );
    if (picked == null || !mounted) return;

    setState(() => _ownRailway = picked.code);
  }

  // Coach type: M_WAGTYPE master (getWagTypeAL).
  Future<void> _openCoachTypePicker() async {
    if (!mounted) return;
    final provider = context.read<LoadingSummaryProvider>();

    var items = provider.wagTypeMasters;
    if (items.isEmpty) {
      await _fetchThenPop("Fetching coach type…", provider.loadWagTypeMasters);
      if (!mounted) return;
      items = provider.wagTypeMasters;
    }

    if (items.isEmpty) {
      _toast(
        "Unable to load coach type list. "
        "(${provider.wagTypeError.isNotEmpty ? provider.wagTypeError : "no data"})",
      );
      return;
    }

    final picked = await _showMasterPicker<WagType>(
      title: "Select Coach Type",
      headerIcon: Icons.directions_bus_outlined,
      itemIcon: Icons.directions_bus,
      searchHint: "Search coach type…",
      emptyText: "No matching coach type",
      items: items,
      labelOf: (w) => w.type,
      searchOf: (w) => "${w.type} ${w.detail}",
      selectedLabel: _coachType,
      confirmLabel: "OK",
    );
    if (picked == null || !mounted) return;

    setState(() => _coachType = picked.type);
  }

  // Wagon-Rly-No.: the train's own consist (GET_TRAIN_CONSIST), where every
  // option is COACHTYPE-OWNRLY-COACHNO.
  Future<void> _openWagonRlyNoPicker() async {
    if (!mounted) return;

    final trainNo = _currentTrainNo();
    if (trainNo.isEmpty) {
      _toast("Enter the train number first.");
      return;
    }

    final scheduleDate = _currentScheduleDate();
    if (scheduleDate.isEmpty) {
      _toast(
        "Schedule date not found. Go back and press SUBMIT on the Loading "
        "page once, then try again.",
      );
      return;
    }

    final provider = context.read<LoadingSummaryProvider>();

    // Rebuild only when the cached list belongs to another train/date.
    if (!provider.isConsistFor(trainNo, scheduleDate)) {
      await _fetchThenPop(
        "Fetching train consist…",
        () => provider.loadCoachDetails(trainNo, scheduleDate),
      );
      if (!mounted) return;
    }

    final items = provider.coachDetails;
    if (items.isEmpty) {
      _toast(
        "Unable to load coach list. "
        "(${provider.consistError.isNotEmpty ? provider.consistError : "no data"})",
      );
      return;
    }

    final picked = await _showMasterPicker<CoachDetail>(
      title: "Select Wagon-Rly-No.",
      headerIcon: Icons.train_outlined,
      itemIcon: Icons.confirmation_number_outlined,
      searchHint: "Search coach…",
      emptyText: "No matching coach",
      items: items,
      labelOf: (c) => c.display,
      selectedLabel: _wagonRlyNo,
      confirmLabel: "OK",
    );
    if (picked == null || !mounted) return;

    setState(() => _wagonRlyNo = picked.display);
  }

  Future<void> _openSealToStationPicker() async {
    final trainNo = _currentTrainNo();
    if (trainNo.isEmpty) {
      _toast("Enter the train number first.");
      return;
    }

    final provider = context.read<LoadingSummaryProvider>();

    // Seal to Station reads M_TRNDTLS, which is filled from getTrndtls on the
    // Loading page. If it is empty, ask to re-validate the train first.
    // Only the user's login station onwards is shown in the list.
    final loginStation = LoginService.loggedInStation;
    await _fetchThenPop(
      "Fetching seal to station…",
      () => provider.loadSealStations(trainNo, fromStation: loginStation),
    );
    if (!mounted) return;

    final items = provider.sealStations;
    if (items.isEmpty) {
      _toast(
        "Seal to Station options not available. "
        "(${provider.sealStationsError.isNotEmpty ? provider.sealStationsError : "no data"})",
      );
      return;
    }

    final picked = await _showMasterPicker<SealStation>(
      title: "Select Seal to Station",
      headerIcon: Icons.location_on_outlined,
      itemIcon: Icons.flag_outlined,
      searchHint: "Search station…",
      emptyText: "No matching station",
      items: items,
      labelOf: (s) => s.label,
      selectedLabel: _sealToStation,
      confirmLabel: "OK",
    );
    if (picked == null || !mounted) return;

    setState(() => _sealToStation = picked.stnCode);
  }

  /// Train number of the validated train (set on the Loading page).
  String _currentTrainNo() {
    // The Loading screen stores the validated train in the shared session;
    // fall back to the last validation result when the session is empty.
    final fromSession = TrainSession.trainNo.trim();
    if (fromSession.isNotEmpty) return fromSession;
    return context
            .read<LoadingProvider>()
            .lastTrainValidation
            ?.trainNo
            .trim() ??
        "";
  }

  /// Schedule date as dd-MM-yyyy (the format GET_TRAIN_CONSIST expects).
  ///
  /// ICMS/NTES frequently returns nothing, so the sources are tried in order:
  ///   1. currentScheduledDate - the date shown on the Loading screen (best)
  ///   2. fetchedJDate          - NTES STD / PTT_STD
  ///   3. lastValidateResult    - date validateTrain returned
  /// DateTime.tryParse() cannot read the dd-MMM-yyyy form, so it is parsed
  /// manually.
  String _currentScheduleDate() {
    final loading = context.read<LoadingProvider>();
    final candidates = <String>[
      loading.currentScheduledDate.trim(),
      loading.fetchedJDate.trim(),
      loading.lastValidateResult?.scheduled.trim() ?? "",
    ];

    for (final raw in candidates) {
      if (raw.isEmpty) continue;
      final parsed = _parseScheduleDate(raw);
      if (parsed == null) continue;

      final mm = parsed.month.toString().padLeft(2, '0');
      final dd = parsed.day.toString().padLeft(2, '0');
      final out = "$dd-$mm-${parsed.year}";
      print("WAGON-CONSIST date source: [$raw] -> stdate [$out]");
      return out;
    }

    print(
      "WAGON-CONSIST: no usable schedule date. "
      "currentScheduledDate=[${loading.currentScheduledDate}] "
      "fetchedJDate=[${loading.fetchedJDate}] "
      "lastValidateResult.scheduled=[${loading.lastValidateResult?.scheduled}]",
    );
    return "";
  }

  static const Map<String, int> _monthIndex = {
    "JAN": 1,
    "FEB": 2,
    "MAR": 3,
    "APR": 4,
    "MAY": 5,
    "JUN": 6,
    "JUL": 7,
    "AUG": 8,
    "SEP": 9,
    "OCT": 10,
    "NOV": 11,
    "DEC": 12,
  };

  /// Accepts dd-MMM-yyyy HH:mm (NTES) as well as ISO yyyy-MM-dd.
  static DateTime? _parseScheduleDate(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;

    final m1 = RegExp(
      r"^(\d{1,2})-([A-Za-z]{3})-(\d{4})(?:\s+(\d{1,2}):(\d{2}))?",
    ).firstMatch(text);
    if (m1 != null) {
      final mon = _monthIndex[m1.group(2)!.toUpperCase()];
      if (mon == null) return null;
      return DateTime(
        int.parse(m1.group(3)!),
        mon,
        int.parse(m1.group(1)!),
        int.tryParse(m1.group(4) ?? '0') ?? 0,
        int.tryParse(m1.group(5) ?? '0') ?? 0,
      );
    }

    // yyyy-MM-dd (optionally with time)
    final m2 = RegExp(
      r"^(\d{4})-(\d{1,2})-(\d{1,2})(?:\s+(\d{1,2}):(\d{2}))?",
    ).firstMatch(text);
    if (m2 != null) {
      return DateTime(
        int.parse(m2.group(1)!),
        int.parse(m2.group(2)!),
        int.parse(m2.group(3)!),
        int.tryParse(m2.group(4) ?? '0') ?? 0,
        int.tryParse(m2.group(5) ?? '0') ?? 0,
      );
    }

    return null;
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shows a blocking spinner, runs [load], then closes the spinner.
  Future<void> _fetchThenPop(
    String message,
    Future<void> Function() load,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 15, color: _labelGrey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await load();
    if (mounted) Navigator.of(context).pop();
  }

  /// One reusable master picker for Platform / Own Railway / Coach type /
  /// Wagon-Rly-No. — same blue header, search box, checkbox list and
  /// Cancel / SUBMIT footer.
  Future<T?> _showMasterPicker<T>({
    required String title,
    required IconData headerIcon,
    required IconData itemIcon,
    required String searchHint,
    required String emptyText,
    required List<T> items,
    required String Function(T) labelOf,
    String Function(T)? searchOf,
    String? selectedLabel,
    String? selectedValue,
    String Function(T)? identityOf,
    String confirmLabel = "SUBMIT",
  }) async {
    T? tempSel;
    for (final item in items) {
      final same = identityOf != null
          ? selectedValue != null && identityOf(item) == selectedValue
          : labelOf(item) == selectedLabel;
      if (same) {
        tempSel = item;
        break;
      }
    }
    String query = "";

    return await showDialog<T>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = query.isEmpty
                ? items
                : items
                      .where(
                        (i) => (searchOf?.call(i) ?? labelOf(i))
                            .toLowerCase()
                            .contains(query),
                      )
                      .toList();

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: _pmsBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(headerIcon, color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: TextField(
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: searchHint,
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 20,
                            color: _labelGrey,
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        onChanged: (v) => setDialogState(
                          () => query = v.trim().toLowerCase(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  emptyText,
                                  style: const TextStyle(
                                    color: _labelGrey,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            )
                          : Scrollbar(
                              thumbVisibility: true,
                              child: ListView(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                children: filtered.map((item) {
                                  final isSel = identical(item, tempSel);
                                  return CheckboxListTile(
                                    value: isSel,
                                    onChanged: (v) => setDialogState(() {
                                      tempSel = (v ?? false) ? item : null;
                                    }),
                                    activeColor: _pmsBlue,
                                    dense: true,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(
                                      labelOf(item),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    secondary: Icon(
                                      itemIcon,
                                      size: 22,
                                      color: isSel
                                          ? _pmsBlue
                                          : Colors.grey.shade400,
                                    ),
                                    selected: isSel,
                                    selectedTileColor: _pmsBlue.withValues(
                                      alpha: 0.06,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade300,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: _labelGrey,
                              textStyle: const TextStyle(fontSize: 15),
                            ),
                            child: const Text("Cancel"),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: tempSel == null
                                ? null
                                : () => Navigator.of(ctx).pop(tempSel),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pmsBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                                vertical: 10,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Text(confirmLabel),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Inside Locked: same dialog look as Platform No. (blue header, single
  // select checkbox list, Cancel/SUBMIT) but fed by the hardcoded options.
  Future<void> _openInsideLockedPicker() async {
    if (!mounted) return;

    final picked = await _showSimpleOptionPicker(
      title: "Select Inside Locked",
      icon: Icons.lock_outline,
      options: _insideLockedOptions,
      current: _insideLocked,
    );

    if (picked == null || !mounted) return;
    setState(() => _insideLocked = picked);
  }

  Future<String?> _showSimpleOptionPicker({
    required String title,
    required IconData icon,
    required List<String> options,
    String? current,
  }) async {
    String? tempSel = current;

    return await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: _pmsBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        children: options.map((option) {
                          final isSel = tempSel == option;
                          return CheckboxListTile(
                            value: isSel,
                            onChanged: (v) => setDialogState(() {
                              tempSel = (v ?? false) ? option : null;
                            }),
                            activeColor: _pmsBlue,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              option,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            secondary: Icon(
                              Icons.lock_outline,
                              size: 22,
                              color: isSel ? _pmsBlue : Colors.grey.shade400,
                            ),
                            selected: isSel,
                            selectedTileColor: _pmsBlue.withValues(alpha: 0.06),
                          );
                        }).toList(),
                      ),
                    ),

                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade300,
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: _labelGrey,
                              textStyle: const TextStyle(fontSize: 15),
                            ),
                            child: const Text("Cancel"),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: tempSel == null
                                ? null
                                : () => Navigator.of(ctx).pop(tempSel),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pmsBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                                vertical: 10,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text("SUBMIT"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Nil Loading/Unloading Reason dropdown — same look as Platform No. and
  /// Seal to Station (blue header, search, single-select checkbox, OK). The
  /// options are hardcoded, matching the Angular page.
  Future<void> _openNilReasonPicker() async {
    final picked = await _showMasterPicker<String>(
      title: "Select Nil Reason",
      headerIcon: Icons.report_outlined,
      itemIcon: Icons.check_box_outlined,
      searchHint: "Search reason…",
      emptyText: "No matching reason",
      items: _nilOptions,
      labelOf: (r) => r,
      selectedLabel: _nilReason,
      confirmLabel: "OK",
    );
    if (picked == null || !mounted) return;
    setState(() => _nilReason = picked);
  }

  // ---------- Flat UI helpers (same as other pages) ----------

  // Grey bold label on top.
  Widget _fieldLabel(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: _labelGrey,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Bordered box around every field's control.
  Widget _fieldBox({required Widget child, double height = 40}) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: child,
    );
  }

  // Row of equal-width field columns.
  Widget _formRow(List<Widget> cells) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: cells[i]),
        ],
      ],
    );
  }

  // Dropdown control (value/hint + small grey arrow).
  Widget _dropdownControl({
    required String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              value != null && value.isNotEmpty ? value : hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: value != null && value.isNotEmpty
                    ? _valueBlack
                    : _hintGrey,
                fontSize: 15,
              ),
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: _labelGrey, size: 24),
        ],
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 4),
        _fieldBox(
          child: _dropdownControl(value: value, hint: hint, onTap: onTap),
        ),
      ],
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 4),
        _fieldBox(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  inputFormatters: inputFormatters,
                  keyboardType: inputFormatters == null
                      ? TextInputType.text
                      : TextInputType.number,
                  style: const TextStyle(color: _valueBlack, fontSize: 15),
                  cursorColor: _pmsBlue,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: _hintGrey, fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _checkPill(String label, bool value, ValueChanged<bool> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 4),
        _fieldBox(
          child: Row(
            children: [
              Checkbox(
                value: value,
                activeColor: _pmsBlue,
                checkColor: Colors.white,
                onChanged: (v) => onChanged(v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _valueBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Drawer ----------

  Widget _drawerItem(IconData icon, String text, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Icon(icon, size: 22, color: _labelGrey),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _valueBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: _bgLight,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 100,
            color: _appBarGreen,
            padding: const EdgeInsets.all(14),
            alignment: Alignment.topRight,
            child: ClipOval(
              child: Image.network(
                _irLogoUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.train, color: Colors.white, size: 38),
              ),
            ),
          ),
          _drawerItem(Icons.home, "Home", () {
            // Welcome is the root screen now; simply go back to it.
            Navigator.pop(context);
            Navigator.popUntil(context, (route) => route.isFirst);
          }),
          const Divider(height: 1, color: _dividerGrey),
          _drawerItem(
            Icons.grid_view,
            "Mis Report",
            () => Navigator.pop(context),
          ),
          const Divider(height: 1, color: _dividerGrey),
          _drawerItem(Icons.search, "PRR Status", () => Navigator.pop(context)),
          const Divider(height: 1, color: _dividerGrey),
          _drawerItem(
            Icons.qr_code,
            "Print Barcode",
            () => Navigator.pop(context),
          ),
          const Divider(height: 1, color: _dividerGrey),
          _drawerItem(
            Icons.delete_outline,
            "Delete Old Data",
            () => Navigator.pop(context),
          ),
          const Divider(height: 1, color: _dividerGrey),
          _drawerItem(
            Icons.star_border,
            "Reload Masters",
            () => Navigator.pop(context),
          ),
          const Divider(height: 1, color: _dividerGrey),
          _drawerItem(Icons.login, "Login", () {
            Navigator.pop(context); // drawer band
            context.read<SplashViewModel>().logout();
            Navigator.popUntil(context, (route) => route.isFirst);
          }),
          const Divider(height: 1, color: _dividerGrey),
          _drawerItem(Icons.logout, "Log Out", () {
            Navigator.pop(context); // drawer band
            context.read<SplashViewModel>().logout();
            Navigator.popUntil(context, (route) => route.isFirst);
          }),
        ],
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hMargin = size.width > 420 ? 14.0 : 10.0;

    // Platform No: comes from NTES when the train number is entered (real data, no fake)
    final ntes = context.watch<LoadingProvider>().ntesDetail;
    final String platformPrefill =
        (ntes != null && ntes.platformNumber.isNotEmpty && _platform == null)
        ? "PLATFORM NO. ${ntes.platformNumber}"
        : "";

    return Scaffold(
      backgroundColor: _bgLight,
      // Shared app bar - same design as every other page in the app.
      appBar: const PMSAppBar(title: "Loading Summary", showBackButton: true),

      drawer: _drawer(context),

      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(decoration: BoxDecoration(color: _bgLight)),
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: hMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _formRow([
                    _dropdownField(
                      label: "Platform No:",
                      value: _platform,
                      hint: platformPrefill.isNotEmpty
                          ? platformPrefill
                          : "PLATFORM NO....",
                      onTap: _openPlatformNoPicker,
                    ),
                    _dropdownField(
                      label: "Inside Locked:",
                      value: _insideLocked,
                      hint: "Select",
                      onTap: _openInsideLockedPicker,
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // Tick -> only Wagon-Rly-No. Untick -> Coach type, Own Railway, Coach no.
                  _formRow([
                    _checkPill(
                      "Accept ICMS Wagon:",
                      _acceptIcmsWagon,
                      (v) => setState(() => _acceptIcmsWagon = v),
                    ),
                    if (_acceptIcmsWagon)
                      _dropdownField(
                        label: "Wagon-Rly-No.:",
                        value: _wagonRlyNo,
                        hint: "Select Wagon",
                        onTap: _openWagonRlyNoPicker,
                      )
                    else
                      _dropdownField(
                        label: "Coach type:",
                        value: _coachType,
                        hint: "Select Coach Type",
                        onTap: _openCoachTypePicker,
                      ),
                  ]),
                  if (!_acceptIcmsWagon) ...[
                    const SizedBox(height: 10),
                    _formRow([
                      _dropdownField(
                        label: "Own Railway:",
                        value: _ownRailway,
                        hint: "Select Own Railway",
                        onTap: _openOwnRailwayPicker,
                      ),
                      _textField(
                        label: "Coach no.:",
                        controller: _coachNoController,
                        hint: "Enter Coach No",
                      ),
                    ]),
                  ],
                  const SizedBox(height: 10),
                  _formRow([
                    _textField(
                      label: "RPF:",
                      controller: _rpfController,
                      hint: "Enter RPF",
                    ),
                    _textField(
                      label: "Guard Mobile No:",
                      controller: _guardMobileController,
                      hint: "Enter 10 digit mobile no",
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 10),
                  _formRow([
                    _textField(
                      label: "Remarks:",
                      controller: _remarksController,
                      hint: "Enter Remarks",
                    ),
                    _checkPill(
                      "Sealed:",
                      _sealed,
                      (v) => setState(() => _sealed = v),
                    ),
                  ]),
                  if (_sealed) ...[
                    const SizedBox(height: 10),
                    _formRow([
                      _dropdownField(
                        label: "Seal to Station:",
                        value: _sealToStation,
                        hint: "Select",
                        onTap: () => _openSealToStationPicker(),
                      ),
                      _dropdownField(
                        label: "Nil Loading/Unloading Reason:",
                        value: _nilReason,
                        hint: "Select",
                        onTap: () => _openNilReasonPicker(),
                      ),
                    ]),
                  ] else ...[
                    const SizedBox(height: 10),
                    _formRow([
                      _textField(
                        label: "Guard Name:",
                        controller: _guardNameController,
                        hint: "Enter Guard Name",
                      ),
                      _textField(
                        label: "Guard HQTR:",
                        controller: _guardHqtrController,
                        hint: "Enter Guard HQTR",
                      ),
                    ]),
                    const SizedBox(height: 10),
                    _dropdownField(
                      label: "Nil Loading/Unloading Reason:",
                      value: _nilReason,
                      hint: "Select",
                      onTap: () => _openNilReasonPicker(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(hMargin, 8, hMargin, 10),
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pmsBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.check_circle, size: 20),
              label: const Text(
                "SUBMIT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

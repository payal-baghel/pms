import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/pages/home/pms_drawer.dart';
import 'package:flutter_application_1/pages/loading/loading_provider.dart';
import 'package:flutter_application_1/pages/loading/models/icms_response.dart';
import 'package:flutter_application_1/pages/loading/models/wagon_master.dart';
import 'package:flutter_application_1/pages/scanData/scan_data_page.dart';
import 'package:flutter_application_1/services/loading_guidance.dart';
import 'package:flutter_application_1/services/login_api.dart';
import 'package:flutter_application_1/services/train_session.dart';
import 'package:flutter_application_1/widgets/pms_appbar.dart';
import 'package:provider/provider.dart';

enum PmsDialogType { info, success, warning, error }

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController scheduledDepController = TextEditingController();
  final TextEditingController actualLoadController = TextEditingController();
  final TextEditingController wagonTypeController = TextEditingController();
  final TextEditingController trainNoController = TextEditingController();

  bool _showGuidance = false;
  bool _loadingGuidance = false;
  Timer? _ntesDebounce;

  // Page colors now come from the shared design system (AppColors), so the
  // whole app re-themes from a single place.
  static const Color _appBarGreen = const Color(0xFF1565C0);
  static const Color _pmsBlue = const Color(0xFF1565C0);
  static const Color _labelGrey = Colors.grey;
  static const Color _valueColor = const Color(0xFF111111);

  static const String _bannerImageUrl =
      "https://images.unsplash.com/photo-1474487548417-781cb71495f3?auto=format&fit=crop&w=1200&q=60";

  // Same size for label, value and hint — formal and aligned.
  static const double _fieldFont = 14;

  static const TextStyle _valueStyle = TextStyle(
    color: _valueColor,
    fontSize: _fieldFont,
  );

  static const TextStyle _hintStyle = TextStyle(
    color: Colors.grey,
    fontSize: _fieldFont,
  );

  static String _formatDateTime(DateTime dt) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "${dt.day.toString().padLeft(2, '0')}-"
        "${months[dt.month - 1]}-"
        "${dt.year} $hh:$mm";
  }

  @override
  void initState() {
    super.initState();

    // Start state: current date & time (should not be left blank).
    // The loading happens at the current time, so the schedule sits 2 hours
    // before it.
    final now = DateTime.now();
    actualLoadController.text = _formatDateTime(now);
    scheduledDepController.text = _formatDateTime(
      now.subtract(const Duration(hours: 2)),
    );

    Future.microtask(() {
      context.read<LoadingProvider>().loadWagonTypes();
    });
  }

  @override
  void dispose() {
    _ntesDebounce?.cancel();
    scheduledDepController.dispose();
    actualLoadController.dispose();
    wagonTypeController.dispose();
    trainNoController.dispose();
    super.dispose();
  }

  // Fetch NTES details as the train number is typed (with debounce).
  void _scheduleNtesFetch(String value) {
    _ntesDebounce?.cancel();
    _ntesDebounce = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _fillDatesFromNtes(value.trim());
    });
  }

  void _onTrainEntered(String value) {
    _ntesDebounce?.cancel();
    if (!mounted) return;
    _fillDatesFromNtes(value.trim());
  }

  // NTES fetch -> Scheduled Dep. (STD/PTT_STD) + Actual Load (ETD/ATD,
  // only if departed) — the date/time will be overridden when the train
  // number is entered.
  Future<void> _fillDatesFromNtes(String value) async {
    final p = context.read<LoadingProvider>();
    await p.fetchNtesDetail(value, tdate: _scheduledDateForApi());

    if (!mounted) return;

    if (p.fetchedJDate.isNotEmpty) {
      scheduledDepController.text = p.fetchedJDate;
    }
    if (p.fetchedADate.isNotEmpty) {
      actualLoadController.text = p.fetchedADate;
    }
  }

  // ---------- Schedule Dep. / Actual Load validation ----------
  // Direct port of the mentor's rule. His JS compares against three
  // timestamps:
  //   dt_time  = now + 2 hours
  //   dt_time1 = now - 7 days
  //   dt_time2 = dt_time + 24 hours   (PEXP trains only)
  String? _loadingDateError() {
    final now = DateTime.now();
    final dtTime = now.add(const Duration(hours: 2));
    final dtTime1 = now.subtract(const Duration(days: 7));
    final dtTime2 = dtTime.add(const Duration(hours: 24));

    final jDate = _parseDateTime(scheduledDepController.text);
    final aDate = _parseDateTime(actualLoadController.text);

    // The actual load can never sit in the future - it must be now or earlier.
    // Example: a train scheduled yesterday may be loaded on 01-Oct 12:10,
    // but never at a time later than the current one.
    if (aDate != null && aDate.isAfter(now)) {
      return "*Advance loading are not allowed!";
    }

    // jDate >= dt_time
    if (jDate != null && jDate.compareTo(dtTime) >= 0) {
      return "*schedule departure time should not be more than 2 hours in advance!";
    }

    // jDate < dt_time1 || aDate < dt_time1
    if ((jDate != null && jDate.compareTo(dtTime1) < 0) ||
        (aDate != null && aDate.compareTo(dtTime1) < 0)) {
      return "*only 7 days old loading to be allowed!";
    }

    // PEXP trains get an extra 24 hours on top of the 2 hour buffer.
    final trainType =
        context.read<LoadingProvider>().lastTrainValidation?.trainType.trim() ??
        "";
    if (trainType.toUpperCase() == "PEXP" &&
        jDate != null &&
        jDate.compareTo(dtTime2) >= 0) {
      return "*schedule departure time should not be more than 24 hours in advance!";
    }

    // The actual load may only happen between 2 hours and 7 days after the
    // scheduled departure time. Anything outside that window is not allowed.
    if (jDate != null && aDate != null) {
      final loadFrom = jDate.add(const Duration(hours: 2));
      final loadTill = jDate.add(const Duration(days: 7));
      if (aDate.compareTo(loadFrom) < 0 || aDate.compareTo(loadTill) > 0) {
        return "*loading not allowed!";
      }
    }

    return null;
  }

  // Mentor shows the message for 2 seconds, so match that here.
  void _flash(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  // Scheduled Departure Date & Time
  Future<void> pickScheduledDeparture() async {
    final now = DateTime.now();

    // Rule 1 sets the lower edge: no date older than 7 days.
    final firstAllowed = now.subtract(const Duration(days: 7));
    // Nothing may reach dt_time (now + 2 hours), so today is the last day.
    final lastAllowed = now;

    // Open on the date that is already stored, not always on today.
    final stored = _parseDateTime(scheduledDepController.text);
    var openDate = stored ?? now;
    if (openDate.isBefore(firstAllowed)) openDate = firstAllowed;
    if (openDate.isAfter(lastAllowed)) openDate = lastAllowed;

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(openDate.year, openDate.month, openDate.day),
      firstDate: DateTime(
        firstAllowed.year,
        firstAllowed.month,
        firstAllowed.day,
      ),
      lastDate: DateTime(lastAllowed.year, lastAllowed.month, lastAllowed.day),
    );

    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _parseDateTime(scheduledDepController.text) ?? DateTime.now(),
      ),
    );

    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // The pickers only bound the day, so the exact hour/minute stays free here.
    // Validation happens on SUBMIT (same as the mentor's JS), so the picked
    // value is kept as typed.
    setState(() {
      scheduledDepController.text = _formatDateTime(combined);
    });

    // Journey date changed -> re-fetch train details (getTrnDtls) for this
    // date so the route/validity card uses the correct date.
    final trainNo = trainNoController.text.trim();
    if (trainNo.length >= 5) {
      context.read<LoadingProvider>().fetchNtesDetail(
        trainNo,
        tdate: _scheduledDateForApi(),
      );
    }
  }

  // Actual Load Date & Time
  Future<void> pickActualLoadDate() async {
    final now = DateTime.now();

    // Rule 1 sets the lower edge: no date older than 7 days. The upper edge
    // follows the departure time, so a train scheduled in the future can
    // still be loaded before it departs.
    final firstAllowed = now.subtract(const Duration(days: 7));
    final lastAllowed = now;

    // Open on the date that is already stored, not always on today.
    final stored = _parseDateTime(actualLoadController.text);
    var openDate = stored ?? now;
    if (openDate.isBefore(firstAllowed)) openDate = firstAllowed;
    if (openDate.isAfter(lastAllowed)) openDate = lastAllowed;

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(openDate.year, openDate.month, openDate.day),
      firstDate: DateTime(
        firstAllowed.year,
        firstAllowed.month,
        firstAllowed.day,
      ),
      lastDate: DateTime(lastAllowed.year, lastAllowed.month, lastAllowed.day),
    );

    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _parseDateTime(actualLoadController.text) ?? now,
      ),
    );

    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // The pickers only bound the day, so the exact hour/minute stays free here.
    // The mentor validates both dates on SUBMIT (same as his JS), not while
    // picking, so the picked value is kept as typed.
    setState(() {
      actualLoadController.text = _formatDateTime(combined);
    });
  }

  // "dd-MMM-yyyy HH:mm" / "dd/MM/yyyy HH:mm" -> DateTime (best effort)
  static DateTime? _parseDateTime(String input) {
    final monthIndex = {
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

    // dd-MMM-yyyy HH:mm
    final m1 = RegExp(
      r"^(\d{1,2})-([A-Za-z]{3})-(\d{4})\s+(\d{1,2}):(\d{2})",
    ).firstMatch(input.trim());
    if (m1 != null) {
      final mon = monthIndex[m1.group(2)!.toUpperCase()];
      if (mon != null) {
        return DateTime(
          int.parse(m1.group(3)!),
          mon,
          int.parse(m1.group(1)!),
          int.parse(m1.group(4)!),
          int.parse(m1.group(5)!),
        );
      }
    }

    // dd/MM/yyyy HH:mm
    final m2 = RegExp(
      r"^(\d{1,2})[/-](\d{1,2})[/-](\d{4})\s+(\d{1,2}):(\d{2})",
    ).firstMatch(input.trim());
    if (m2 != null) {
      return DateTime(
        int.parse(m2.group(3)!),
        int.parse(m2.group(2)!),
        int.parse(m2.group(1)!),
        int.parse(m2.group(4)!),
        int.parse(m2.group(5)!),
      );
    }

    return null;
  }

  // Journey date for getTrnDtls (dd-MM-yyyy) — from the Scheduled Dep. field,
  // else today.
  String? _scheduledDateForApi() {
    final dt = _parseDateTime(scheduledDepController.text);
    if (dt == null) return null;
    return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
  }

  Future<void> _validateAndFetchTrain(String text) async {
    if (text.trim().isEmpty) return;

    final result = await context.read<LoadingProvider>().validateTrain(
      text,
      scheduledDep: scheduledDepController.text,
    );
    if (!mounted) return;

    // The server dates are the real train schedule, so keep them, but make sure
    // they still satisfy the loading window. If they do not, fall back to the
    // time the user already had (schedule 2 hours before the loading).
    final keepScheduled = scheduledDepController.text;
    final keepActual = actualLoadController.text;

    if (result.scheduled.isNotEmpty) {
      scheduledDepController.text = result.scheduled;
    }
    if (result.actual.isNotEmpty) {
      actualLoadController.text = result.actual;
    }

    if (_loadingDateError() != null) {
      scheduledDepController.text = keepScheduled;
      actualLoadController.text = keepActual;
      setState(() {});
    }

    // Invalid/unknown train -> do nothing, stay on the same page.
    if (!result.ok) {
      return;
    }

    // Mentor's flow after SUBMIT:
    //  - server Decription is empty  -> proceed to the next page
    //    (the same page that opens when "Show Guidance" is ON).
    //  - server Decription is present -> show its text as an alert and
    //    do NOT navigate.
    final decription = result.decription.trim();
    if (decription.isNotEmpty) {
      await _showPmsDialog(
        title: "Validation Failed",
        message: decription,
        type: PmsDialogType.warning,
      );
      return;
    }

    // Proceed to the Scan Data page after a valid train.
    // Hand the on-screen schedule date over, so the Loading Summary page can
    // call GET_TRAIN_CONSIST even when ICMS/NTES returned nothing.
    final loadingProvider = context.read<LoadingProvider>();
    loadingProvider.setCurrentScheduledDate(
      scheduledDepController.text,
    );

    // Store the current loading session (train no, scale, loading time,
    // vehicle) so Scan Data / AddPrr show the real values the user entered
    // instead of hard-coded mocks. ACT_LOADNO is built from this session.
    _storeLoadingSession();

    // Show Guidance ON: the actual load details of the train are fetched from
    // the server and stored locally first, then the Scan Data page opens with
    // every record shown.
    if (_showGuidance) {
      _loadingGuidance = true;
      await _showGuidanceLoader();
      await _loadGuidance();
      _loadingGuidance = false;
      if (!mounted) return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanDataPage()),
    );
    if (mounted) setState(() => _showGuidance = false);
  }

  /// Blocking loader shown while the loading guidance is fetched.
  Future<void> _showGuidanceLoader() async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: const [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 16),
              Text("Fetching load guidance..."),
            ],
          ),
        ),
      ),
    );
  }

  /// Closes the guidance loader.
  void _closeGuidanceLoader() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Fetches the loading guidance (actual load details) of the current train
  /// and stores every record locally for the Scan Data screen.
  Future<({bool ok, int saved, String message})> _loadGuidance() async {
    final guidance = await LoadingGuidance.loadForSession(
      scheduledDate: scheduledDepController.text,
    );
    _closeGuidanceLoader();
    if (!mounted) return guidance;
    if (!guidance.ok || guidance.saved == 0) {
      _flash(guidance.message);
    }
    return guidance;
  }

  /// Copies the on-screen values into the shared loading session, so every
  /// following screen (Scan Data, Add PWB/PRR, loading guidance) works with
  /// the train the user typed instead of empty values.
  void _storeLoadingSession() {
    final loadingProvider = context.read<LoadingProvider>();
    TrainSession.trainNo = trainNoController.text.trim();
    TrainSession.scale = loadingProvider.scale;
    TrainSession.loadDateTime = actualLoadController.text;
    TrainSession.vehicle = loadingProvider.selectedWagonTypesText;
    TrainSession.station = LoginService.loggedInStation ?? "NDLS";
    TrainSession.loadUnloadFlag = "L";
  }

  void submit() {
    if (_loadingGuidance) return;
    final hasVehicle = context
        .read<LoadingProvider>()
        .selectedWagonTypes
        .isNotEmpty;
    if (!hasVehicle) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select Vehicle Type")));
      return;
    }
    // Mentor's rule runs before the form is submitted.
    final dateError = _loadingDateError();
    if (dateError != null) {
      _flash(dateError);
      return;
    }
    if (_formKey.currentState!.validate()) {
      _validateAndFetchTrain(trainNoController.text);
    }
  }

  void clearForm() {
    final now = DateTime.now();
    actualLoadController.text = _formatDateTime(now);
    scheduledDepController.text = _formatDateTime(
      now.subtract(const Duration(hours: 2)),
    );
    trainNoController.clear();
    wagonTypeController.clear();

    context.read<LoadingProvider>().clearForm();
  }

  // Official/enterprise-style dialog: coloured header bar, icon, OK & Cancel.
  Future<void> _showPmsDialog({
    required String title,
    required String message,
    PmsDialogType type = PmsDialogType.info,
    bool showCancel = false,
    String okLabel = "OK",
  }) async {
    if (!mounted) return;

    final (IconData icon, Color headerColor) = switch (type) {
      PmsDialogType.success => (
        Icons.check_circle_outline,
        const Color(0xFF2E7D32),
      ),
      PmsDialogType.error => (Icons.cancel_outlined, const Color(0xFFC62828)),
      PmsDialogType.warning => (
        Icons.warning_amber_rounded,
        const Color(0xFFF57F17),
      ),
      PmsDialogType.info => (Icons.info_outline, const Color(0xFF1565C0)),
    };

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        title: Container(
          color: headerColor,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 12),
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
        content: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xFF333333),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          if (showCancel)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                foregroundColor: _labelGrey,
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: const Text("Cancel"),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: headerColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(okLabel),
          ),
        ],
      ),
    );
  }

  // Vehicle value stored in the session must be the wagon TYPE only,
  // without capacity, so the ACT_LOADNO stays in the mentor's format
  // (e.g. LNDLS20802FCMSLR071026) and the search API gets the same number.
  String _wagonValue(WagonMaster wagon) => wagon.wagonType;

  String _wagonLabel(WagonMaster wagon) =>
      "${wagon.wagonType} - ${wagon.capicity}T";

  // Vehicle Type: chhoti formal window (max ~60% screen height) + scroller.
  Future<void> _openWagonPicker() async {
    final loadingProvider = context.read<LoadingProvider>();

    if (loadingProvider.wagonTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to load vehicle types.")),
      );
      return;
    }

    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String? tempSel = loadingProvider.selectedWagonTypes.isNotEmpty
            ? loadingProvider.selectedWagonTypes.first
            : null;
        String query = "";

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = query.isEmpty
                ? loadingProvider.wagonTypes
                : loadingProvider.wagonTypes
                      .where(
                        (w) => _wagonLabel(w).toLowerCase().contains(query),
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
                    // Formal coloured header bar
                    Container(
                      color: _pmsBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Select Vehicle Type",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search box
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: TextField(
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: "Search vehicle type…",
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                            color: _labelGrey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (v) => setDialogState(
                          () => query = v.trim().toLowerCase(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Scrollable list (chhoti window, andar scroller)
                    Flexible(
                      child: filtered.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  "No matching vehicle type",
                                  style: TextStyle(
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
                                children: filtered.map((wagon) {
                                  final value = _wagonValue(wagon);
                                  final isSel = tempSel == value;
                                  return CheckboxListTile(
                                    value: isSel,
                                    onChanged: (v) => setDialogState(() {
                                      // single-select: check one, uncheck the others
                                      tempSel = (v ?? false) ? value : null;
                                    }),
                                    activeColor: _pmsBlue,
                                    dense: true,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(
                                      _wagonLabel(wagon),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    secondary: Icon(
                                      Icons.train_outlined,
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

                    // Footer actions
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
                            child: const Text("OK"),
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

    if (picked == null) return;

    loadingProvider.setSelectedWagonTypes([picked]);
    wagonTypeController.text = loadingProvider.selectedWagonTypesText;
  }

  // Compact VALID / INVALID status card (mentor: show only valid or
  // invalid on screen, not the train details).
  Widget _trainStatusCard({
    required bool valid,
    required String title,
    required String message,
  }) {
    final color = valid ? _appBarGreen : Colors.red.shade700;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            valid ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Warning card: default English + standard official-style message.
  Widget _trainDataMissingCard(String trainNo) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade700),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade800,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TRAIN DETAILS NOT FOUND",
                  style: TextStyle(
                    color: Color(0xFFB26A00),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Train details could not be fetched for this Train Number"
                  "${trainNo.isEmpty ? "." : " ($trainNo)."} "
                  "This may be a Special train not listed in the schedule "
                  "database. You may proceed by pressing SUBMIT for official "
                  "validation.",
                  style: const TextStyle(
                    color: Color(0xFF8D6E63),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Train no. daalte hi validation card:
  // loading -> spinner | route/ntes -> VALID/INVALID | nothing -> warning.
  Widget? _ntesDetailCard(LoadingProvider provider) {
    // Do not show any validation card until a train number has been entered.
    if (trainNoController.text.trim().isEmpty) {
      return null;
    }

    if (provider.isNtesLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              "Fetching train details…",
              style: TextStyle(color: _labelGrey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final detail = provider.ntesDetail ?? const IcmsResponse();
    final routeDetails = provider.trndtls;
    final hasRoute = routeDetails != null && routeDetails.trnstpg.isNotEmpty;
    final station = LoginService.loggedInStation ?? "NDLS";

    // Route data available (mentor's loop + destination check).
    if (hasRoute) {
      final v = provider.trainRouteVerdict;
      return _trainStatusCard(
        valid: v.$1,
        title: v.$2.isEmpty ? (v.$1 ? "Valid Train" : "Invalid Train") : v.$2,
        message: v.$1 ? "Loading is allowed at station $station." : v.$3,
      );
    }

    // No route data, but the train is confirmed by NTES.
    if (detail.isFound) {
      return _trainStatusCard(
        valid: true,
        title: "Valid Train",
        message: "Loading is allowed at station $station.",
      );
    }

    // No route and no NTES data — data missing (mentor: do not show a
    // wrong invalid alert).
    return _trainDataMissingCard(trainNoController.text.trim());
  }

  // Official form field: label on top (bold, dark), boxed input below.
  Widget _fieldRow(
    String label,
    Widget field, {
    IconData? icon,
    VoidCallback? onIconTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: _labelGrey,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                Expanded(child: field),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onIconTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(icon, color: _appBarGreen, size: 20),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Old simple grey Android switch
  Widget _legacySwitch() {
    return GestureDetector(
      // Toggles the guidance mode only. The guidance API is called when the
      // user presses SUBMIT (see _validateAndFetchTrain), which then opens the
      // Scan Data page.
      onTap: () {
        if (_loadingGuidance) return;
        setState(() => _showGuidance = !_showGuidance);
      },
      child: Container(
        width: 48,
        height: 24,
        decoration: BoxDecoration(
          color: _showGuidance ? _appBarGreen : const Color(0xFFBDBDBD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: _showGuidance
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  // Official panel header: icon chip + bold uppercase title.
  Widget _sectionHeader(String text, {IconData icon = Icons.info_outline}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _appBarGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: _appBarGreen, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF37474F),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Attractive top banner: railway image (google/unsplash) with gradient
  // fallback + overlay chip — offline pe bhi clean dikhega.
  Widget _topBanner() {
    return Container(
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E5E33), Color(0xFF37474F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _bannerImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1B5E20),
                    Color(0xFF2E5E33),
                    Color(0xFF37474F),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // scrim so text readable over image
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black54, Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Parcel Management System",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Loading Summary",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.train, color: Colors.white, size: 13),
                        SizedBox(width: 5),
                        Text(
                          "Indian Railways",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadingProvider = context.watch<LoadingProvider>();
    final ntesCard = _ntesDetailCard(loadingProvider);

    return Scaffold(
      drawer: PmsDrawer.build(
        context,
        username: LoginService.loggedInUserId ?? "",
        station: LoginService.loggedInStation ?? "",
      ),
      // Shared app bar - same design as every other page in the app.
      appBar: const PMSAppBar(title: "Loading Details", showDrawer: true),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(color: const Color(0xFFF5F7F8)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Attractive top banner (railway image + gradient)
                    _topBanner(),

                    const SizedBox(height: 8),

                    // Card A — TRAIN & SCHEDULE
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            "Train & Schedule",
                            icon: Icons.schedule,
                          ),
                          const SizedBox(height: 10),

                          // Train Number
                          _fieldRow(
                            "Train No.",
                            loadingProvider.isTrainValidating
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  )
                                : TextFormField(
                                    controller: trainNoController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.right,
                                    style: _valueStyle,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(5),
                                    ],
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                    ),
                                    onFieldSubmitted: _onTrainEntered,
                                    onChanged: _scheduleNtesFetch,
                                    validator: (value) => value!.trim().isEmpty
                                        ? "Enter Train Number"
                                        : value.trim().length < 5
                                        ? "Enter 5 digit Train Number"
                                        : null,
                                  ),
                            icon: Icons.search,
                          ),

                          // Scheduled Departure
                          _fieldRow(
                            "Scheduled Dep.",
                            TextFormField(
                              controller: scheduledDepController,
                              readOnly: true,
                              textAlign: TextAlign.right,
                              style: _valueStyle,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onTap: pickScheduledDeparture,
                              validator: (value) => value!.isEmpty
                                  ? "Select Scheduled Departure"
                                  : null,
                            ),
                            icon: Icons.event,
                            onIconTap: pickScheduledDeparture,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Card B — LOAD DETAILS
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            "Load Details",
                            icon: Icons.local_shipping,
                          ),
                          const SizedBox(height: 10),

                          // Vehicle Type
                          _fieldRow(
                            "Vehicle Type",
                            loadingProvider.isLoadingTypes
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  )
                                : TextFormField(
                                    controller: wagonTypeController,
                                    readOnly: true,
                                    textAlign: TextAlign.right,
                                    style: _valueStyle,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                      hintText:
                                          loadingProvider.wagonTypes.isEmpty
                                          ? "No vehicle data"
                                          : "Select",
                                      hintStyle: _hintStyle,
                                    ),
                                    onTap: _openWagonPicker,
                                    validator: (value) =>
                                        loadingProvider
                                            .selectedWagonTypes
                                            .isEmpty
                                        ? "Select Vehicle Type"
                                        : null,
                                  ),
                            icon: Icons.local_shipping,
                          ),

                          // Actual Load Date & Time
                          _fieldRow(
                            "Actual Load Date",
                            TextFormField(
                              controller: actualLoadController,
                              readOnly: true,
                              textAlign: TextAlign.right,
                              style: _valueStyle,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onTap: pickActualLoadDate,
                              validator: (value) => value!.isEmpty
                                  ? "Select Actual Load Date"
                                  : null,
                            ),
                            icon: Icons.event_available,
                            onIconTap: pickActualLoadDate,
                          ),

                          // Show Guidance — switch + text + boxed row
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "SHOW GUIDANCE",
                                  style: TextStyle(
                                    color: _labelGrey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F8FA),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      _legacySwitch(),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            _showGuidance
                                                ? "Show Guidance ON"
                                                : "Show Guidance OFF",
                                            maxLines: 1,
                                            style: _valueStyle,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (ntesCard != null) ...[
                      const SizedBox(height: 8),
                      ntesCard,
                      const SizedBox(height: 8),
                    ] else
                      const SizedBox(height: 20),

                    // Standard buttons: SUBMIT filled, CANCEL outlined
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _appBarGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 20),
                                  SizedBox(width: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "SUBMIT",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              // CANCEL -> back to the Welcome page.
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFC62828),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFB71C1C),
                                  width: 1.5,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cancel,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "CANCEL",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

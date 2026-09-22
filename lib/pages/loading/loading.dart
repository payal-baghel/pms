import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/loading/loading_db_helper.dart';
import 'package:flutter_application_1/pages/loading/models/wagon_master.dart';
import 'package:flutter_application_1/services/login_api.dart';
import 'package:flutter_application_1/services/loding_api.dart' as loding_api;

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController scheduledDepController = TextEditingController();
  final List<String> trainNumbers = [];

  String? selectedTrainNo;
  final TextEditingController actualLoadController = TextEditingController();

  bool _loadingTypes = false;
  List<WagonMaster> _wagonTypes = [];
  final List<String> _selectedWagonTypes = [];
  final TextEditingController wagonTypeController = TextEditingController();

  bool _trainValidating = false;

  bool _showGuidance = false;

  static const Color _appBarGreen = Color(0xFF2E5E33);
  static const Color _pmsBlue = Color(0xFF1565C0);
  static const Color _labelGrey = Color(0xFF707070);
  static const Color _valueColor = Colors.black;

  static const String _irLogoUrl = "https://cris.org.in/img/footer/redlogo.png";

  static const TextStyle _labelStyle = TextStyle(
    color: _labelGrey,
    fontSize: 20,
  );

  static const TextStyle _valueStyle = TextStyle(
    color: _valueColor,
    fontSize: 19,
  );

  @override
  void initState() {
    super.initState();
    _loadWagonTypes();
  }

  // Dynamically fetch vehicle types (wagon master) from the API
  Future<void> _loadWagonTypes() async {
    setState(() {
      _loadingTypes = true;
    });

    final types = await loding_api.LoadingService.getWagonMaster();

    List<WagonMaster> toUse;
    if (types.isNotEmpty) {
      await LoadingDbHelper.instance.saveWagonMasters(types);
      toUse = await LoadingDbHelper.instance.getWagonMasters();
    } else {
      toUse = await LoadingDbHelper.instance.getWagonMasters();
    }

    if (!mounted) return;

    setState(() {
      _wagonTypes = toUse;
      _loadingTypes = false;
    });

    if (toUse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vehicle types load nahi hue. Server response empty."),
        ),
      );
    }
  }

  @override
  void dispose() {
    scheduledDepController.dispose();
    var trainNoController;
    trainNoController.dispose();
    actualLoadController.dispose();
    wagonTypeController.dispose();
    super.dispose();
  }

  // Scheduled Departure Date & Time
  Future<void> pickScheduledDeparture() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    setState(() {
      scheduledDepController.text =
          "${pickedDate.day.toString().padLeft(2, '0')}/"
          "${pickedDate.month.toString().padLeft(2, '0')}/"
          "${pickedDate.year} "
          "${pickedTime.format(context)}";
    });
  }

  // Actual Load Date & Time
  Future<void> pickActualLoadDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    setState(() {
      actualLoadController.text =
          "${pickedDate.day.toString().padLeft(2, '0')}/"
          "${pickedDate.month.toString().padLeft(2, '0')}/"
          "${pickedDate.year} "
          "${pickedTime.format(context)}";
    });
  }

  void submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data Submitted Successfully")),
      );
    }
  }

  void clearForm() {
    scheduledDepController.clear();
    var trainNoController;
    trainNoController.clear();
    actualLoadController.clear();

    setState(() {
      _selectedWagonTypes.clear();
      wagonTypeController.clear();
    });
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade300,
    );
  }

  String _juourneyDateIcms() {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}-${months[now.month - 1]}-${now.year}";
  }

  String _trainDateTrndtls() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
  }

  DateTime? _parseIcmDateTime(String value) {
    final match = RegExp(
      r"^(\d{1,2})-([A-Za-z]{3})-(\d{4}) (\d{1,2}):(\d{2})(?::(\d{2}))?$",
    ).firstMatch(value);
    if (match == null) return null;

    const months = {
      "JAN": 1, "FEB": 2, "MAR": 3, "APR": 4, "MAY": 5, "JUN": 6,
      "JUL": 7, "AUG": 8, "SEP": 9, "OCT": 10, "NOV": 11, "DEC": 12,
    };
    final month = months[match.group(2)!.toUpperCase()];
    if (month == null) return null;

    return DateTime(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      match.group(6) != null ? int.parse(match.group(6)!) : 0,
    );
  }

  String _formatIcmDateTime(DateTime dt) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "${dt.day.toString().padLeft(2, '0')}-${months[dt.month - 1]}-${dt.year} $hh:$mm";
  }

  String _icmDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return "";

    final value = raw.trim();
    DateTime? parsed = DateTime.tryParse(value);

    if (parsed == null) {
      parsed = _parseIcmDateTime(value);
    }

    if (parsed == null) return "";

    return _formatIcmDateTime(parsed);
  }

  Future<void> _validateAndFetchTrain(String text) async {
    final trainNo = text.trim();
    if (trainNo.isEmpty) return;

    setState(() {
      _trainValidating = true;
    });

    final userId = LoginService.loggedInUserId ?? "AT";
    final password = LoginService.loggedInPassword ?? "AT";
    final station = LoginService.loggedInStation ?? "NDLS";

    final response = await loding_api.LoadingService.getIcmsData(
      trainNo: trainNo,
      jStation: station,
      jDate: _juourneyDateIcms(),
      userId: userId,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _trainValidating = false;
    });

    if (!response.isValid) {
      await _showOkDialog(
        "Invalid Journey input (Train/Station/Date) !!!",
        response.message.serviceMessage.isNotEmpty
            ? response.message.serviceMessage
            : "Entered train / station / date ka combo valid nahi hai.",
      );
      return;
    }

    if (!response.stopsAtStation(station)) {
      await _showOkDialog(
        "Loading Not Allowed",
        "Train $trainNo iss route mein station $station ka stop nahi hai.\n"
        "Isliye $station se loading allowed nahi hai.",
      );
      return;
    }

    final String sched = _icmDateTime(response.std);
    final String actual = _icmDateTime(response.etd);

    setState(() {
      if (sched.isNotEmpty) {
        scheduledDepController.text = sched;
      }
      if (actual.isNotEmpty) {
        actualLoadController.text = actual;
      }
    });

    await _showOkDialog(
      "Train Valid",
      "Data Found !!! ${response.trainName.isNotEmpty ? response.trainName : trainNo} "
      "($station se loading allowed)\n"
      "Platform: ${response.platformNumber.isNotEmpty ? response.platformNumber : "-"}",
    );

    final details = await loding_api.LoadingService.getTrndtls(
      trainNo: trainNo,
      tdate: _trainDateTrndtls(),
    );

    if (!mounted) return;

    if (details != null) {
      print("TRNDTLS Train: ${details.trainNo} | Name: ${details.trainName} | Stops: ${details.trnstpg.length}");
    }
  }

  Future<void> _showOkDialog(String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String _wagonValue(WagonMaster wagon) =>
      "${wagon.wagonType}-${wagon.capicity}";

  String _wagonLabel(WagonMaster wagon) =>
      "${wagon.wagonType} - ${wagon.capicity}T";

  Future<void> _openWagonPicker() async {
    if (_wagonTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vehicle types load nahi hue.")),
      );
      return;
    }

    final picked = await showDialog<List<String>>(
      context: context,
      builder: (ctx) {
        final temp = <String>[..._selectedWagonTypes];
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text("Select Vehicle Type"),
              content: SizedBox(
                width: 340,
                child: ListView(
                  shrinkWrap: true,
                  children: _wagonTypes.map((wagon) {
                    final value = _wagonValue(wagon);
                    return CheckboxListTile(
                      dense: true,
                      title: Text(_wagonLabel(wagon)),
                      value: temp.contains(value),
                      onChanged: (_) {
                        setDialogState(() {
                          if (temp.contains(value)) {
                            temp.remove(value);
                          } else {
                            temp.add(value);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(temp),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedWagonTypes
        ..clear()
        ..addAll(picked);
      wagonTypeController.text = _selectedWagonTypes.join(", ");
    });
    print("Selected Vehicle Types: $_selectedWagonTypes");
  }

  // Label on the left (never wraps), value/control on the right.
  Widget _fieldRow(String label, Widget field) {
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: _labelStyle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: field,
          ),
        ],
      ),
    );
  }

  // Old simple grey Android switch
  Widget _legacySwitch() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showGuidance = !_showGuidance;
        });
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

  @override
  Widget build(BuildContext context) {
    TextEditingController? trainNoController;

    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _appBarGreen,
        toolbarHeight: size.height * 0.14,
        titleSpacing: 8,
        title: Row(
          children: [
            ClipOval(
              child: Image.network(
                _irLogoUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.train,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  "Loading Summary",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: _pmsBlue,
              image: DecorationImage(
                image: NetworkImage(_irLogoUrl),
                opacity: 0.08,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // White rectangular form panel (upper-middle)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Column(
                      children: [
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
                                vertical: 12,
                              ),
                            ),
                            onTap: pickScheduledDeparture,
                            validator: (value) => value!.isEmpty
                                ? "Select Scheduled Departure"
                                : null,
                          ),
                        ),
                        _divider(),

                        // Vehicle Type
                        _fieldRow(
                          "Vehicle Type",
                          _loadingTypes
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
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    hintText: _wagonTypes.isEmpty
                                        ? "No vehicle data"
                                        : "Select",
                                    hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 19,
                                    ),
                                  ),
                                  onTap: _openWagonPicker,
                                  validator: (value) =>
                                      _selectedWagonTypes.isEmpty
                                          ? "Select Vehicle Type"
                                          : null,
                                ),
                        ),
                        _divider(),

                        // Train Number
                        _fieldRow(
                          "Train No.",
                          _trainValidating
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
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onFieldSubmitted: _validateAndFetchTrain,
                                  validator: (value) => value!.isEmpty
                                      ? "Enter Train Number"
                                      : null,
                                ),
                        ),
                        _divider(),

                        // Show Guidance — old interface: switch LEFT, text after it
                        SizedBox(
                          height: 48,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
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
                            ],
                          ),
                        ),
                        _divider(),

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
                                vertical: 12,
                              ),
                            ),
                            onTap: pickActualLoadDate,
                            validator: (value) => value!.isEmpty
                                ? "Select Actual Load Date"
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Large side-by-side pill buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pmsBlue,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              "SUBMIT ✓",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: clearForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _appBarGreen,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              "CANCEL ×",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
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
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/barcode_decoder.dart';
import '../widgets/pms_appbar.dart';
import 'package:flutter_datawedge/flutter_datawedge.dart';
import '../database_helper.dart';
import '../pages/addPrr/add_prr_provider.dart';
import '../services/scanner_broadcast.dart';
import '../services/load_capacity.dart';
import '../services/train_session.dart';
import '../widgets/pms_alert.dart';

class ScanningPage extends StatefulWidget {
  /// When true (Left Over Pkg = ON) the same QR may be scanned again without
  /// the "already scanned" alert. When false (Left Over Pkg = OFF) a repeated
  /// QR shows the "already scanned" alert.
  final bool allowMultipleScan;

  const ScanningPage({super.key, this.allowMultipleScan = false});

  @override
  State<ScanningPage> createState() => _ScanningPageState();
}

class _ScanningPageState extends State<ScanningPage> {
  List<Map<String, dynamic>> records = [];
  Set<String> scannedBarcodes = {};

  List<bool> selectedRows = [];

  // Hardware scanner broadcast stream (Flutter port of the Cordova
  // ScannerPlugin: action "android.decode.scan_result", extra "code_data").
  StreamSubscription<String>? _hardwareScanSub;

  @override
  void initState() {
    super.initState();
    _hardwareScanSub = ScannerBroadcast.scans.listen(
      _onHardwareScan,
      onError: (e) => debugPrint("Hardware scan stream error: $e"),
    );
  }

  @override
  void dispose() {
    _hardwareScanSub?.cancel();
    super.dispose();
  }

  /// Handles a raw scan string pushed by the hardware scanner.
  /// Mirrors the mentor's plugin logic: GS1 barcodes are longer than 85
  /// chars and decoded differently from the normal PWB/PRR barcode.
  void _onHardwareScan(String value) {
    if (value.isEmpty) return;

    if (value.length > 85) {
      // GS1 barcode — separate decoder not implemented yet.
      debugPrint("GS1 barcode received (len=${value.length})");
      return;
    }

    final decoded = BarcodeDecoder.decode(value);
    if (decoded["error"] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid barcode format")),
      );
      return;
    }
    addOrMergeRecord(decoded);
  }

  Future<void> addOrMergeRecord(Map<String, dynamic> result) async {
    if (result["error"] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid barcode format")),
      );
      return;
    }

    final String barcode = result["rawBarcode"] ?? "";
    final String prr = result["prr"].toString();
    final String newItem = result["itemNo"].toString();

    final int existingIndex = records.indexWhere(
      (row) => row["prr"].toString() == prr,
    );

    // A repeat is the SAME QR (raw barcode) OR the SAME package (PRR + item
    // number) already scanned. Only blocked when multiple scan is NOT allowed.
    final bool duplicate =
        !widget.allowMultipleScan &&
        (scannedBarcodes.contains(barcode) ||
            (existingIndex != -1 &&
                records[existingIndex]["itemNo"]
                    .toString()
                    .split('~')
                    .contains(newItem)));

    if (duplicate) {
      _showAlreadyScannedDialog();
      return;
    }

    // Booking type and item type come from the barcode itself (first digit of
    // the PWB/PRR), so the BKT column of the Scan Data page is filled
    // automatically - no dropdown pick needed.
    final String bookingType = (result["bookingType"]?.toString() ?? "").trim();
    final String itemType = (result["itemType"]?.toString() ?? "").trim();
    final double scanWeight = (result["weight"] as num?)?.toDouble() ?? 0;

    // The label also carries the booked values, so the loaded packages and
    // the loaded weight can be checked against them right away.
    final int bookedPkg = (result["totalPackets"] as num?)?.toInt() ?? 0;
    final double bookedWt = _bookedWeightOf(result);

    // What is already loaded for this PWB/PRR: the rows of this session list
    // plus the local DB row (a scan done before the app was restarted).
    final dbRow = await DatabaseHelper.instance.getActLoadTlsFallback(
      actLoadNo: TrainSession.actLoadNo,
      pwbltno: int.tryParse(prr) ?? 0,
    );
    final bool dbRowScanned =
        (int.tryParse(dbRow?['SCANALL']?.toString() ?? '0') ?? 0) == 1;
    final int dbLoadedPkg =
        dbRowScanned
        ? (int.tryParse(dbRow?['NOOFITEMSLOADED']?.toString() ?? '') ?? 0)
        : 0;
    final double dbLoadedWt =
        dbRowScanned
        ? (double.tryParse(dbRow?['LDWT']?.toString() ?? '') ?? 0)
        : 0;
    final int memLoadedPkg =
        existingIndex == -1
            ? 0
            : ((records[existingIndex]["scannedPackets"] as num?)?.toInt() ?? 0);
    final double memLoadedWt =
        existingIndex == -1
            ? 0
            : ((records[existingIndex]["weight"] as num?)?.toDouble() ?? 0);
    final int basePkg = memLoadedPkg > dbLoadedPkg ? memLoadedPkg : dbLoadedPkg;
    final double baseWt = memLoadedWt > dbLoadedWt ? memLoadedWt : dbLoadedWt;

    // After this scan the PWB/PRR will have these loaded values.
    final int newPkg = basePkg + 1;
    final double newWt = baseWt + scanWeight;

    // Loaded packages cannot be more than the booked ones.
    if (bookedPkg > 0 && newPkg > bookedPkg) {
      if (!mounted) return;
      await PmsAlert.show(
        context,
        title: "INVALID LD PKG",
        message:
            "Loaded package count ($newPkg) cannot exceed the booked package "
            "count ($bookedPkg) of PWB/PRR $prr.",
      );
      return;
    }

    // Loaded weight cannot be more than the booked weight. When the label
    // stores the weights rounded to whole kg, a fraction of a kg over the
    // booked weight is allowed.
    final double wtTolerance = (result["weightRounded"] == true) ? 1.0 : 0.0;
    if (bookedWt > 0 && newWt > bookedWt + wtTolerance) {
      if (!mounted) return;
      await PmsAlert.show(
        context,
        title: "INVALID LD WT",
        message:
            "Loaded weight (${newWt.toStringAsFixed(2)} kg) cannot exceed "
            "the booked weight (${bookedWt.toStringAsFixed(2)} kg) of "
            "PWB/PRR $prr.",
      );
      return;
    }

    // Vehicle capacity guard: a scan that would take the loaded weight over
    // the vehicle capacity (e.g. FCFSLR 3.9 T = 3900 kg) is rejected.
    final capacityKg = await LoadCapacity.capacityKg();
    if (capacityKg != null) {
      final dbRowWeight = double.tryParse(dbRow?['LDWT']?.toString() ?? '') ?? 0;
      final loadedKg = await LoadCapacity.loadedWeightKg();
      final projected = loadedKg - dbRowWeight + newWt;
      if (projected > capacityKg) {
        if (!mounted) return;
        await PmsAlert.show(
          context,
          title: "VEHICLE CAPACITY EXCEEDED",
          message: LoadCapacity.capacityMessage(
            totalKg: projected,
            capacityKg: capacityKg,
          ),
        );
        return;
      }
    }

    setState(() {
      scannedBarcodes.add(barcode);

      if (existingIndex == -1) {
        // Item Type / Booking Type come from the barcode, not from a
        // dropdown, so they are only filled when the label carries them.
        result["itemType"] = itemType;
        result["bookingType"] = bookingType;
        // The loaded values include what was already loaded for this PRR.
        result["scannedPackets"] = newPkg;
        result["weight"] = newWt;
        records.add(result);
        selectedRows.add(false);
      } else {
        records[existingIndex]["weight"] = newWt;
        records[existingIndex]["scannedPackets"] = newPkg;
        if (itemType.isNotEmpty) {
          records[existingIndex]["itemType"] = itemType;
        }
        if (bookingType.isNotEmpty) {
          records[existingIndex]["bookingType"] = bookingType;
        }

        // Collect every scanned item number of this RR (dedupe) and store
        // them ascending as "1~2~3~4" / "1~3~4" (left-out items just missing).
        final items = <int>{};
        for (final part
            in records[existingIndex]["itemNo"].toString().split('~')) {
          final n = int.tryParse(part.trim());
          if (n != null) items.add(n);
        }
        final parsedNew = int.tryParse(newItem.trim());
        if (parsedNew != null) items.add(parsedNew);
        final sortedItems = items.toList()..sort();
        records[existingIndex]["itemNo"] = sortedItems.join('~');
      }
    });

    // Persist the (merged) record to the local DB so it shows up on the Scan
    // Data screen too, just like a row saved from the Add PWB/PRR form.
    final targetIndex = existingIndex == -1 ? records.length - 1 : existingIndex;
    await _saveRecordToDb(records[targetIndex]);
  }

  /// Booked weight of a parcel, read from the barcode: the total booked
  /// weight is used, the total chargeable weight is the fallback.
  double _bookedWeightOf(Map<String, dynamic> record) {
    final booked = (record["bookedWeight"] as num?)?.toDouble() ?? 0;
    if (booked > 0) return booked;
    return (record["totalChargeableWeight"] as num?)?.toDouble() ?? 0;
  }

  /// Popup shown when the same barcode is scanned a second time.
  void _showAlreadyScannedDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Already Scanned"),
        content: const Text("This barcode has already been scanned."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Upserts one scanned record into ACT_LOADTLS_FALLBACK (PK: PWBLTNO +
  /// ACT_LOADNO), so a camera/device scan and an Add PWB/PRR save write the
  /// same local row.
  Future<void> _saveRecordToDb(Map<String, dynamic> record) async {
    final prr = record["prr"]?.toString() ?? "";
    // Loaded values (what is really in the vehicle for this PWB/PRR).
    final weight = (record["weight"] as num?)?.toDouble() ?? 0;
    final scannedPackets = (record["scannedPackets"] as num?)?.toInt() ?? 0;
    // Booked values (read from the barcode label).
    final totalPackets = (record["totalPackets"] as num?)?.toInt() ?? 0;
    final bookedWeight = (record["bookedWeight"] as num?)?.toDouble() ?? 0;
    final totalChargeableWeight =
        (record["totalChargeableWeight"] as num?)?.toDouble() ?? 0;
    final source = record["source"]?.toString() ?? "";
    final destination = record["destination"]?.toString() ?? "";
    final commodityCode = (record["commodityCode"]?.toString() ?? "").trim();
    final pkgDesc = (record["pkgDesc"]?.toString() ?? "").trim();
    final scale = (record["scale"]?.toString() ?? "").trim();

    try {
      await DatabaseHelper.instance.insertActLoadTlsFallback({
        'ACT_LOADNO': TrainSession.actLoadNo,
        'PWBLTNO': int.tryParse(prr) ?? 0,
        // NOT NULL columns without a form field; 0 keeps the row valid.
        'CONSIGNOR_MOBILE_NO': 0,
        'CONSIGNEE_MOBILE_NO': 0,
        'MAJCOMMD':
            commodityCode.isEmpty
                ? "0"
                : AddPrrProvider.comodityShortForm(commodityCode),
        'NOOFITEMSLOADED': scannedPackets,
        'NOP_SCANNED': scannedPackets,
        'PKG_DESC': pkgDesc,
        'STNFROM': source,
        'STNCODE': source,
        'DSTNSTN': destination,
        'BOOK_DT': record["bookingDate"]?.toString() ?? "",
        // Booked package count, straight from the label.
        'BKDPACKAGE': totalPackets,
        // Booking type + item type, derived from the first digit of the PRR.
        'BKTYPE': record["bookingType"]?.toString() ?? "",
        'PKGTYPE': record["itemType"]?.toString() ?? "",
        // Booked weight vs loaded weight.
        'BKWT': bookedWeight,
        'LDWT': weight,
        'TOTCHRGWT': totalChargeableWeight > 0 ? totalChargeableWeight : bookedWeight,
        'VEHICLE_NO': TrainSession.vehicle,
        // 1 = this row came from a barcode SCAN (mentor's flag).
        'SCANALL': 1,
        'ITEMNOS': record["itemNo"]?.toString() ?? "",
        'SCALE': scale.isEmpty ? TrainSession.scale : scale,
        'LOAD_DT': TrainSession.loadDateTime,
        'SYSTEM_DT': DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint(
        "Scan saved to ACT_LOADTLS_FALLBACK -> ACT_LOADNO: "
        "${TrainSession.actLoadNo} | PWBLTNO: $prr | Wt: $weight",
      );
    } catch (e) {
      debugPrint("Scan DB insert error: $e");
    }
  }

  Future<void> openCamera() async {
    var result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScanPage()),
    );

    if (result != null) {
      addOrMergeRecord(result);
    }
  }

  Future<void> openDeviceScanner() async {
    var result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeviceScannerPage()),
    );

    if (result != null) {
      addOrMergeRecord(result);
    }
  }

  void deleteSelectedRows() {
    setState(() {
      for (int i = selectedRows.length - 1; i >= 0; i--) {
        if (selectedRows[i]) {
          scannedBarcodes.remove(records[i]["rawBarcode"]);
          records.removeAt(i);
          selectedRows.removeAt(i);
        }
      }
    });
  }

  /// Persists one row's edited Item Type / Booking Type to the local DB.
  Future<void> _updateRowOption(int rowIndex, String key, String value) async {
    setState(() {
      records[rowIndex][key] = value;
    });
    await _saveRecordToDb(records[rowIndex]);
  }

  double getTotalWeight() {
    double total = 0;

    for (var item in records) {
      total += (item["weight"] ?? 0);
    }

    return total;
  }

  int getTotalPackets() {
    int total = 0;

    for (var item in records) {
      total += (item["totalPackets"] ?? 0) as int;
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PMSAppBar(
        title: "Loading",
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: deleteSelectedRows,
          ),
        ],
      ),
      body: records.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: openCamera,
                    child: const Text("Scan with Camera"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: openDeviceScanner,
                    child: const Text("Scan with Device Scanner"),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text("Select")),
                  DataColumn(label: Text("PRR")),
                  DataColumn(label: Text("Weight")),
                  DataColumn(label: Text("Packets")),
                  DataColumn(label: Text("Scanned")),
                  DataColumn(label: Text("Item")),
                  DataColumn(label: Text("Item Type")),
                  DataColumn(label: Text("Booking Type")),
                  DataColumn(label: Text("Source")),
                  DataColumn(label: Text("Dest")),
                  DataColumn(label: Text("Date")),
                ],
                rows: [
                  ...List.generate(records.length, (index) {
                    final data = records[index];

                    return DataRow(
                      cells: [
                        DataCell(
                          Checkbox(
                            value: selectedRows[index],
                            onChanged: (value) {
                              setState(() {
                                selectedRows[index] = value ?? false;
                              });
                            },
                          ),
                        ),
                        DataCell(Text(data["prr"].toString())),
                        DataCell(Text(data["weight"].toString())),
                        DataCell(Text(data["totalPackets"].toString())),
                        DataCell(Text(data["scannedPackets"].toString())),
                        DataCell(Text(data["itemNo"].toString())),
                        DataCell(
                          Builder(
                            builder: (_) {
                              final opts = AddPrrProvider.itemTypesForPrr(
                                data["prr"]?.toString() ?? "",
                              );
                              final current =
                                  data["itemType"]?.toString() ?? "";
                              return DropdownButton<String>(
                                value: opts.contains(current) ? current : null,
                                hint: const Text("Select"),
                                underline: const SizedBox.shrink(),
                                items: opts
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(
                                          "$t (${AddPrrProvider.itemTypeLabel(t)})",
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    _updateRowOption(index, "itemType", v);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        DataCell(
                          DropdownButton<String>(
                            value:
                                (data["bookingType"]?.toString().isNotEmpty ??
                                    false)
                                ? data["bookingType"].toString()
                                : null,
                            hint: const Text("Select"),
                            underline: const SizedBox.shrink(),
                            items: AddPrrProvider.bookingTypes
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                _updateRowOption(index, "bookingType", v);
                              }
                            },
                          ),
                        ),
                        DataCell(Text(data["source"].toString())),
                        DataCell(Text(data["destination"].toString())),
                        DataCell(Text(data["bookingDate"].toString())),
                      ],
                    );
                  }),

                  DataRow(
                    color: WidgetStateProperty.all(Colors.grey.shade300),
                    cells: [
                      const DataCell(
                        Text(
                          "TOTAL",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const DataCell(Text("")),
                      DataCell(
                        Text(
                          getTotalWeight().toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          getTotalPackets().toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                    ],
                  ),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "cam",
            onPressed: openCamera,
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "dev",
            onPressed: openDeviceScanner,
            child: const Icon(Icons.qr_code),
          ),
        ],
      ),
    );
  }
}

class CameraScanPage extends StatefulWidget {
  const CameraScanPage({super.key});

  @override
  State<CameraScanPage> createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> {
  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PMSAppBar(title: "Camera Scanner", showBackButton: true),
      body: MobileScanner(
        onDetect: (barcodeCapture) {
          if (scanned) return;

          for (final barcode in barcodeCapture.barcodes) {
            final code = barcode.rawValue;

            if (code != null) {
              scanned = true;

              final decoded = BarcodeDecoder.decode(code);

              Navigator.pop(context, decoded);
              break;
            }
          }
        },
      ),
    );
  }
}

class DeviceScannerPage extends StatefulWidget {
  const DeviceScannerPage({super.key});

  @override
  State<DeviceScannerPage> createState() => _DeviceScannerPageState();
}

class _DeviceScannerPageState extends State<DeviceScannerPage> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  late FlutterDataWedge dataWedge;

  @override
  void initState() {
    super.initState();

    dataWedge = FlutterDataWedge();

    dataWedge.onScanResult.listen((scan) {
      if (scan.data != null && scan.data!.isNotEmpty) {
        debugPrint("Zebra Intent Scan: ${scan.data}");
        processScan(scan.data!);
      }
    });

    Future.delayed(Duration.zero, () {
      FocusScope.of(context).requestFocus(focusNode);
    });
  }

  void processScan(String value) {
    debugPrint("Received Barcode: $value");
    if (value.isEmpty) return;

    final decoded = BarcodeDecoder.decode(value);

    Navigator.pop(context, decoded);
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PMSAppBar(title: "Device Scanner", showBackButton: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Ready for Hardware Scanner",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text("Scan using device scanner"),
              const SizedBox(height: 30),
              TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Scanner Input",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: processScan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

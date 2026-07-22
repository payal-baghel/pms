import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/barcode_decoder.dart';
import 'package:flutter_datawedge/flutter_datawedge.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  List<Map<String, dynamic>> records = [];
  Set<String> scannedBarcodes = {};

  List<bool> selectedRows = [];

  void addOrMergeRecord(Map<String, dynamic> result) {
    String barcode = result["rawBarcode"] ?? "";

    if (scannedBarcodes.contains(barcode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Barcode already scanned"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    String prr = result["prr"];

    int existingIndex = records.indexWhere((row) => row["prr"] == prr);

    setState(() {
      scannedBarcodes.add(barcode);

      if (existingIndex == -1) {
        records.add(result);
        selectedRows.add(false);
      } else {
        records[existingIndex]["weight"] =
            (records[existingIndex]["weight"] as num) +
            (result["weight"] as num);

        records[existingIndex]["scannedPackets"] =
            (records[existingIndex]["scannedPackets"] as int) + 1;

        String existingItems = records[existingIndex]["itemNo"].toString();
        String newItem = result["itemNo"].toString();

        List<String> itemList = existingItems.split(',');

        if (!itemList.contains(newItem)) {
          records[existingIndex]["itemNo"] = "$existingItems,$newItem";
        }
      }
    });
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

  void editCell(int rowIndex, String key, dynamic currentValue) {
    TextEditingController controller = TextEditingController(
      text: currentValue.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit $key"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: key,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (key == "weight") {
                    records[rowIndex][key] =
                        double.tryParse(controller.text) ?? 0;
                  } else if (key == "totalPackets" || key == "scannedPackets") {
                    records[rowIndex][key] = int.tryParse(controller.text) ?? 0;
                  } else {
                    records[rowIndex][key] = controller.text;
                  }
                });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
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
      appBar: AppBar(
        title: const Text("Loading"),
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
                        DataCell(
                          Text(data["prr"].toString()),
                          onTap: () => editCell(index, "prr", data["prr"]),
                        ),
                        DataCell(
                          Text(data["weight"].toString()),
                          onTap: () =>
                              editCell(index, "weight", data["weight"]),
                        ),
                        DataCell(
                          Text(data["totalPackets"].toString()),
                          onTap: () => editCell(
                            index,
                            "totalPackets",
                            data["totalPackets"],
                          ),
                        ),
                        DataCell(
                          Text(data["scannedPackets"].toString()),
                          onTap: () => editCell(
                            index,
                            "scannedPackets",
                            data["scannedPackets"],
                          ),
                        ),
                        DataCell(
                          Text(data["itemNo"].toString()),
                          onTap: () =>
                              editCell(index, "itemNo", data["itemNo"]),
                        ),
                        DataCell(
                          Text(data["source"].toString()),
                          onTap: () =>
                              editCell(index, "source", data["source"]),
                        ),
                        DataCell(
                          Text(data["destination"].toString()),
                          onTap: () => editCell(
                            index,
                            "destination",
                            data["destination"],
                          ),
                        ),
                        DataCell(
                          Text(data["bookingDate"].toString()),
                          onTap: () => editCell(
                            index,
                            "bookingDate",
                            data["bookingDate"],
                          ),
                        ),
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
      appBar: AppBar(title: const Text("Camera Scanner")),
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
      appBar: AppBar(title: const Text("Device Scanner")),
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

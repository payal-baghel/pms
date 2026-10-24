import 'package:flutter/material.dart';
import 'package:flutter_application_1/database_helper.dart';
import 'package:flutter_application_1/pages/addPrr/add_prr_page.dart';
import 'package:flutter_application_1/pages/addPrr/add_prr_provider.dart';
import 'package:flutter_application_1/pages/loadingSummary/loading_summary_detail.dart';
import 'package:flutter_application_1/pages/scanData/scan_data_provider.dart';
import 'package:flutter_application_1/scanning/scanning.dart';
import 'package:flutter_application_1/services/load_capacity.dart';
import 'package:flutter_application_1/utils/booking_date.dart';
import 'package:flutter_application_1/widgets/pms_alert.dart';
import 'package:flutter_application_1/widgets/pms_appbar.dart';
import 'package:provider/provider.dart';

/// "Scan Data" screen — GUI only (MVVM View), matching the reference layout.
/// Shows the PWB/PRR rows saved locally (ACT_LOADTLS_FALLBACK) in a table.
class ScanDataPage extends StatefulWidget {
  const ScanDataPage({super.key});

  @override
  State<ScanDataPage> createState() => _ScanDataPageState();
}

class _ScanDataPageState extends State<ScanDataPage> {
  @override
  void initState() {
    super.initState();
    // Load rows from the local DB every time the screen opens, so newly
    // saved entries from the Add PWB/PRR form appear right away.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanDataProvider>().refresh();
    });
  }

  // Shared design system (single source of truth).

  // White band that holds "20802, Scale: R, ..." above the column header.
  static const Color _trainInfoBg = const Color(0xFFFFFFFF);
  static const Color _headerGreyBlue = const Color(0xFFF5F7F8);
  static const Color _greenButton = const Color(0xFF2E7D32);
  static const Color _lightBlueButton = const Color(0xFF1565C0);

  // Independent per-row selection state for the "Select" column.
  final Set<int> _selectedIds = <int>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E3E6),
      // Shared app bar - same design as every other page in the app.
      appBar: const PMSAppBar(title: "Scan Data", showBackButton: true),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Light grey backdrop, matching the rest of the app. The old dark
          // blue gradient made the black text unreadable.
          const DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFFE0E3E6)),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _trainInfoRow(context.read<ScanDataProvider>()),
                _tableSection(),
                _bottomControls(context, context.read<ScanDataProvider>()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Train information row (white card) ----------
  Widget _trainInfoRow(ScanDataProvider provider) {
    final values = [
      provider.trainNumber,
      "Scale: ${provider.scale}",
      provider.dateTime,
      provider.vehicle,
    ];

    return Container(
      width: double.infinity,
      color: _trainInfoBg,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < values.length; i++) ...[
              Text(
                values[i],
                style: const TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (i < values.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "•",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- Table column header ----------
  // Column order matches the Add PWB/PRR form fields.
  static const List<String> _columns = [
    "Select",
    "ID",
    "PRR Number",
    "FRMS",
    "DEST",
    "PKG",
    "WGT",
    "Booking Date",
    "Commodity",
    "Fare",
    "BKT",
  ];

  Widget _tableSection() {
    return Consumer<ScanDataProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingRows) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            ),
          );
        }
        if (provider.loadError.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              provider.loadError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD32F2F)),
            ),
          );
        }
        if (provider.rows.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.inbox_outlined, color: Colors.blueGrey, size: 40),
                SizedBox(height: 8),
                Text(
                  "No PWB/PRR saved yet.\nGo to ADD and save an entry from the local DB.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [Shadow(color: Colors.black38, offset: Offset(0, 1))],
                  ),
                ),
              ],
            ),
          );
        }
        return _dataTable(provider.rows);
      },
    );
  }

  Widget _dataTable(List<ScanDataRow> rows) {
    // Totals are summed from the LOADED values of every record in the table
    // (Ld Wt / Ld Pkg), matching the reference screen. A value may be a plain
    // number or a "value/count" pair, so only the value component is taken —
    // the two halves of a pair are never added together.
    double totalWt = 0;
    int totalPkg = 0;
    for (final r in rows) {
      totalWt += _weightValue(r.ldWt);
      totalPkg += _pkgCount(r.ldPkg);
    }
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFB0BEC5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _tableHeader(),
                      ...rows.asMap().entries.map(
                        (e) => _tableRow(e.value, e.key + 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _totalsBar(totalWt, totalPkg),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      color: _headerGreyBlue,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _cell("Select", bold: true, color: Colors.black, minWidth: 64),
          for (final c in _columns.skip(1))
            _cell(c, bold: true, color: Colors.black, minWidth: 96),
        ],
      ),
    );
  }

  // Totals shown directly below the table: Total Weight on the left and
  // Total Pkg on the right, both bold black so they stay readable and aligned.
  Widget _totalsBar(double totalWt, int totalPkg) {
    const style = TextStyle(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: Text("Total Weight ${_fmtNum(totalWt)}", style: style),
          ),
          Expanded(
            child: Text(
              "Total Pkg $totalPkg",
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Weight component of a value such as "59.93" or "200/2". Only the weight
  /// half is used; the package-count half of a "w/c" pair is ignored.
  double _weightValue(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return 0;
    return double.tryParse(s.split('/').first.trim()) ?? 0;
  }

  /// Package count of a value such as "2" or "2/2". Only the count half is
  /// used; the other half of the pair is ignored.
  int _pkgCount(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return 0;
    final first = s.split('/').first.trim();
    return int.tryParse(first) ?? (double.tryParse(first)?.round() ?? 0);
  }

  // Whole numbers show without decimals; otherwise trailing zeros are trimmed.
  String _fmtNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    var s = v.toStringAsFixed(3);
    while (s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s;
  }

  Widget _tableRow(ScanDataRow r, int id) {
    // Scan Data table columns, in order (after ID): PRR, FRMS, DEST, PKG,
    // WGT, Booking Date, Commodity, Fare, BKT.
    final values = <String>[
      r.pwbltno, // PRR Number
      r.srcStn, // FRMS
      r.destStn, // DEST
      r.pkgDisplay, // PKG  -> "booked/loaded" (e.g. "16/1", "16/16")
      r.bkdWt, // WGT
      r.bookingDate, // Booking Date
      r.comodityLabel, // Commodity
      r.fare, // Fare
      r.bkgType, // BKT
    ];
    // Update is locked for scanned rows (SCANALL = 1); only rows the user
    // saved by hand may be edited. Update / delete appear only once the row
    // is selected.
    final canEdit = !r.isScanned;
    final isSelected = _selectedIds.contains(id);
    return GestureDetector(
      onTap: (canEdit && isSelected) ? () => _openEditDialog(r) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFECEFF1))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            // Row select control. Only one RR can be selected at a time, so
            // picking a new row clears the previous selection.
            SizedBox(
              width: 64,
              child: Center(
                child: Checkbox(
                  value: _selectedIds.contains(id),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeColor: _greenButton,
                  onChanged: (v) {
                    setState(() {
                      _selectedIds.clear();
                      if (v == true) _selectedIds.add(id);
                    });
                    // Selecting a row opens the DELETE / CHECK ALL dialog.
                    if (v == true) {
                      _showSelectDialog(r);
                    }
                  },
                ),
              ),
            ),
            // ID + every data cell are selectable (long-press to copy).
            _cell(id.toString(), minWidth: 96, selectable: true),
            for (final v in values) _cell(v, minWidth: 96, selectable: true),
            // Update icon appears only when this row is selected (delete is
            // done from the selection dialog's DELETE button).
            SizedBox(
              width: 88,
              child: isSelected && canEdit
                  ? IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Color(0xFF1565C0),
                      ),
                      tooltip: "Update",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _openEditDialog(r),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Selection dialog: DELETE / CHECK ALL / CANCEL ----------
  // Opens when a row's Select checkbox is ticked. The PRR is shown dynamically.
  Future<void> _showSelectDialog(ScanDataRow r) async {
    final action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You Have Selected ${r.pwbltno}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Do you want to delete or Check All this PRR/PWB?",
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, "delete"),
                        child: const Text(
                          "DELETE",
                          style: TextStyle(
                            color: Color(0xFF212121),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, "checkall"),
                        child: const Text(
                          "CHECK ALL",
                          style: TextStyle(
                            color: Color(0xFF212121),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, "cancel"),
                        child: const Text(
                          "CANCEL",
                          style: TextStyle(
                            color: Color(0xFF212121),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (action == "delete") {
      await _deleteRow(r);
    } else if (action == "checkall") {
      final provider = context.read<ScanDataProvider>();
      await provider.checkAll(r);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("All packages marked loaded for ${r.pwbltno}"),
        ),
      );
    }
    // "cancel" -> close with nothing changed.
  }

  // ---------- Row delete (only reachable for a selected row) ----------
  Future<void> _deleteRow(ScanDataRow r) async {
    final provider = context.read<ScanDataProvider>();
    await provider.deleteRow(r);
    if (mounted) setState(_selectedIds.clear);
  }

  // ---------- Row editor (tap a row or the edit icon) ----------
  Future<void> _openEditDialog(ScanDataRow r) async {
    final provider = context.read<ScanDataProvider>();

    final pwbltnoCtrl = TextEditingController(text: r.pwbltno);
    final srcCtrl = TextEditingController(text: r.srcStn);
    final destCtrl = TextEditingController(text: r.destStn);
    final dateCtrl = TextEditingController(
      text: BookingDate.normalize(r.bookingDate),
    );
    final bkdPkgCtrl = TextEditingController(text: r.bkdPkg);
    final ldPkgCtrl = TextEditingController(text: r.ldPkg);
    final bkdWtCtrl = TextEditingController(text: r.bkdWt);
    final ldWtCtrl = TextEditingController(text: r.ldWt);
    final fareCtrl = TextEditingController(text: r.fare);
    final remarksCtrl = TextEditingController(text: r.remarks);
    final rackCtrl = TextEditingController(text: r.rackNo);

    String itemType = r.pkgType;
    String bookingType = r.bkgType;
    // Commodity is held as a code ("1".."9") for the dropdown; the DB stores
    // the short form ("HP"..), so convert on the way in and out.
    String comodity = AddPrrProvider.comodityCodeFromShort(r.comodityType);

    // Pkg Condn / Pkg Desc dropdown sources: the masters synced after login
    // (M_PKGCONDN / M_PKG_DESC) — the same lists the Add PWB/PRR page uses.
    final addProvider = context.read<AddPrrProvider>();
    await addProvider.loadPkgCondnsFromDb();
    await addProvider.loadPkgDescsFromDb();
    if (!mounted) return;

    final pkgCondnOpts = <String>{
      ...addProvider.pkgCondnCodes,
      if (r.pkgCondn.isNotEmpty) r.pkgCondn,
    }.toList();
    final pkgDescOpts = <String>{
      ...addProvider.pkgDescList,
      if (r.pkgDesc.isNotEmpty) r.pkgDesc,
    }.toList();

    String pkgCondn = r.pkgCondn;
    String pkgDesc = r.pkgDesc;

    // Inputs for the UPDATE validations:
    //  - capacityKg: vehicle capacity from the wagon master (null = unknown).
    //  - otherLoadedWt: loaded weight of the other rows of this session.
    final capacityKg = await LoadCapacity.capacityKg();
    if (!mounted) return;
    final otherLoadedWt = await LoadCapacity.loadedWeightExcludingKg(
      pwbltno: r.pwbltnoInt,
      actLoadNo: r.actLoadNo,
    );
    if (!mounted) return;

    final doUpdate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text("Update Details"),
              content: SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Read-only field (not editable by the user).
                      _editField("PWB/PRR No", pwbltnoCtrl, readOnly: true),
                      // A 10-digit PWB/PRR No is a SYSTEM booking, so the Item
                      // Type must stay "S"; choosing anything else warns.
                      _editDropdown(
                        label: "Item Type",
                        value: AddPrrProvider.itemTypes.contains(itemType)
                            ? itemType
                            : null,
                        items: AddPrrProvider.itemTypes,
                        itemLabel: (t) =>
                            "$t (${AddPrrProvider.itemTypeLabel(t)})",
                        onChanged: (v) {
                          setDialogState(() => itemType = v);
                          // A 10-digit PWB/PRR No is a SYSTEM booking: warn
                          // with an alert window when another type is picked.
                          if (r.pwbltno.length >= 10 && v != "S") {
                            PmsAlert.show(
                              context,
                              title: "INVALID ITEM TYPE",
                              message:
                                  "A 10-digit PWB/PRR No is a SYSTEM booking, "
                                  "so the Item Type must be SYSTEM (S). "
                                  "The row cannot be updated with Item Type $v.",
                            );
                          }
                        },
                      ),
                      _editDropdown(
                        label: "Booking Type",
                        value:
                            (bookingType.isNotEmpty &&
                                AddPrrProvider.bookingTypes.contains(
                                  bookingType,
                                ))
                            ? bookingType
                            : null,
                        items: AddPrrProvider.bookingTypes,
                        itemLabel: (t) => t,
                        onChanged: (v) =>
                            setDialogState(() => bookingType = v),
                      ),
                      _editField("Source Stn", srcCtrl, readOnly: true),
                      _editField("Dest Stn", destCtrl, readOnly: true),
                      _editField(
                        "Booking Date",
                        dateCtrl,
                        onEditingComplete: () =>
                            dateCtrl.text = BookingDate.normalize(dateCtrl.text),
                        readOnly: true,
                        suffixIcon: const Icon(Icons.calendar_month, size: 20),
                        onTap: () async {
                          final now = DateTime.now();
                          DateTime initial = now;
                          final parsed = BookingDate.tryParse(dateCtrl.text);
                          if (parsed != null) initial = parsed;
                          if (!dialogContext.mounted) return;
                          final date = await showDatePicker(
                            context: dialogContext,
                            initialDate: initial,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date == null || !dialogContext.mounted) return;
                          final time = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay.fromDateTime(initial),
                          );
                          if (time == null || !dialogContext.mounted) return;
                          final picked = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                          setDialogState(
                            () => dateCtrl.text = BookingDate.format(picked),
                          );
                        },
                      ),
                      _editField(
                        "Bkd Pkg",
                        bkdPkgCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      _editField(
                        "Ld Pkg",
                        ldPkgCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      _editField(
                        "Bkd Wt",
                        bkdWtCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      _editField(
                        "Ld Wt",
                        ldWtCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      _editDropdown(
                        label: "Comodity",
                        value: AddPrrProvider.comodityTypes.contains(comodity)
                            ? comodity
                            : null,
                        items: AddPrrProvider.comodityTypes,
                        itemLabel: AddPrrProvider.comodityLabel,
                        onChanged: (v) => setDialogState(() => comodity = v),
                      ),
                      _editField(
                        "Fare",
                        fareCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      // Editable fields.
                      _editDropdown(
                        label: "Pkg Condn",
                        value: pkgCondn.isEmpty ? null : pkgCondn,
                        items: pkgCondnOpts,
                        itemLabel: addProvider.pkgCondnLabel,
                        onChanged: (v) => setDialogState(() => pkgCondn = v),
                      ),
                      _editDropdown(
                        label: "Pkg Desc",
                        value: pkgDesc.isEmpty ? null : pkgDesc,
                        items: pkgDescOpts,
                        itemLabel: addProvider.pkgDescLabel,
                        onChanged: (v) => setDialogState(() => pkgDesc = v),
                      ),
                      _editField("Remarks", remarksCtrl),
                      _editField("Rack No", rackCtrl),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final bkdPkgText = bkdPkgCtrl.text.trim();
                    final ldPkgText = ldPkgCtrl.text.trim();
                    final bkdWtText = bkdWtCtrl.text.trim();
                    final ldWtText = ldWtCtrl.text.trim();
                    final fareText = fareCtrl.text.trim();
                    final prr = pwbltnoCtrl.text.trim();

                    dateCtrl.text = BookingDate.normalize(dateCtrl.text);

                    // Every validation failure is shown in a formal alert
                    // window instead of a message inside the form.
                    final bkdPkg = int.tryParse(bkdPkgText);
                    final ldPkg = int.tryParse(ldPkgText);
                    final bkdWt = double.tryParse(bkdWtText);
                    final ldWt = double.tryParse(ldWtText);
                    final fare = double.tryParse(fareText);

                    (String, String)? error;
                    if (prr.length != 10) {
                      error = (
                        "INVALID PRR NO",
                        "PWB/PRR No must be a 10-digit number. Entered "
                            "value: '$prr'.",
                      );
                    } else if (prr.length >= 10 && itemType != "S") {
                      error = (
                        "INVALID ITEM TYPE",
                        "A 10-digit PWB/PRR No is a SYSTEM booking, so the "
                            "Item Type must be SYSTEM (S).",
                      );
                    } else if (bkdPkg == null) {
                      error = (
                        "INVALID BKD PKG",
                        "Enter a valid whole number for the booked package "
                            "count. Entered value: '$bkdPkgText'.",
                      );
                    } else if (ldPkg == null) {
                      error = (
                        "INVALID LD PKG",
                        "Enter a valid whole number for the loaded package "
                            "count. Entered value: '$ldPkgText'.",
                      );
                    } else if (ldPkg > bkdPkg) {
                      error = (
                        "INVALID LD PKG",
                        "Loaded package count ($ldPkg) cannot exceed the "
                            "booked package count ($bkdPkg).",
                      );
                    } else if (bkdWt == null) {
                      error = (
                        "INVALID BKD WT",
                        "Enter a valid weight for the booked weight. "
                            "Entered value: '$bkdWtText'.",
                      );
                    } else if (ldWt == null) {
                      error = (
                        "INVALID LD WT",
                        "Enter a valid weight for the loaded weight. "
                            "Entered value: '$ldWtText'.",
                      );
                    } else if (ldWt > bkdWt) {
                      error = (
                        "INVALID LD WT",
                        "Loaded weight (${_fmtNum(ldWt)} kg) cannot exceed the "
                            "booked weight (${_fmtNum(bkdWt)} kg).",
                      );
                    } else if (fare == null) {
                      error = (
                        "INVALID FARE",
                        "Enter a valid fare. Entered value: '$fareText'.",
                      );
                    } else if (capacityKg != null &&
                        (otherLoadedWt + ldWt) > capacityKg) {
                      error = (
                        "VEHICLE CAPACITY EXCEEDED",
                        LoadCapacity.capacityMessage(
                          totalKg: otherLoadedWt + ldWt,
                          capacityKg: capacityKg,
                        ),
                      );
                    }

                    if (error != null) {
                      await PmsAlert.show(
                        context,
                        title: error.$1,
                        message: error.$2,
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text("UPDATE"),
                ),
              ],
            );
          },
        );
      },
    );

    if (doUpdate != true) return;

    final src = srcCtrl.text.trim();
    final bkdWtVal = double.tryParse(bkdWtCtrl.text.trim()) ?? 0;
    final fareVal = double.tryParse(fareCtrl.text.trim()) ?? 0;

    final values = <String, Object?>{
      'PWBLTNO': int.tryParse(pwbltnoCtrl.text.trim()) ??
          (int.tryParse(r.pwbltno) ?? 0),
      'PKGTYPE': itemType,
      'BKTYPE': bookingType,
      'STNFROM': src,
      'STNCODE': src,
      'DSTNSTN': destCtrl.text.trim(),
      'BOOK_DT': BookingDate.normalize(dateCtrl.text.trim()),
      'BKDPACKAGE': int.tryParse(bkdPkgCtrl.text.trim()) ?? 0,
      'NOOFITEMSLOADED': int.tryParse(ldPkgCtrl.text.trim()) ?? 0,
      'TOTCHRGWT': bkdWtVal,
      'BKWT': bkdWtVal,
      'LDWT': double.tryParse(ldWtCtrl.text.trim()) ?? 0,
      'MAJCOMMD': AddPrrProvider.comodityShortForm(comodity),
      'TOTCHRG': fareVal,
      'PKGCND': pkgCondn,
      'PKG_DESC': pkgDesc,
      'REMARKS': remarksCtrl.text.trim(),
      'RACKNO': rackCtrl.text.trim(),
    };

    try {
      final rowsAffected =
          await DatabaseHelper.instance.updateActLoadTlsFallbackRow(
        origPwbltno: int.tryParse(r.pwbltno) ?? 0,
        actLoadNo: r.raw['ACT_LOADNO']?.toString() ?? "",
        values: values,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rowsAffected > 0
                ? "Row updated in DB ($rowsAffected row)"
                : "Nothing updated — no matching row in DB.",
          ),
        ),
      );
      await provider.refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    }
  }

  Widget _editField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    TextInputType? keyboardType,
    VoidCallback? onEditingComplete,
    Widget? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        showCursor: !readOnly,
        enableInteractiveSelection: !readOnly,
        keyboardType: keyboardType,
        onEditingComplete: onEditingComplete,
        onTap: onTap,
        style: TextStyle(
          color: readOnly ? const Color(0xFF555555) : const Color(0xFF111111),
        ),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: readOnly,
          fillColor: readOnly ? const Color(0xFFF2F4F7) : null,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _editDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String Function(String) itemLabel,
    required ValueChanged<String> onChanged,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: readOnly,
          fillColor: readOnly ? const Color(0xFFF2F4F7) : null,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map(
              (t) => DropdownMenuItem(value: t, child: Text(itemLabel(t))),
            )
            .toList(),
        onChanged: readOnly
            ? null
            : (v) {
                if (v != null) onChanged(v);
              },
      ),
    );
  }

  Widget _cell(
    String text, {
    bool bold = false,
    Color? color,
    double minWidth = 96,
    bool selectable = false,
  }) {
    final style = TextStyle(
      color: color ?? const Color(0xFF111111),
      fontSize: 13,
      fontWeight: bold ? FontWeight.bold : FontWeight.w400,
    );
    return SizedBox(
      width: minWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: selectable
            ? SelectableText(
                text,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: style,
              )
            : Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: style,
              ),
      ),
    );
  }

  // ---------- Bottom controls: Left Over Pkg + small buttons at screen bottom ----------
  Widget _bottomControls(BuildContext context, ScanDataProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _leftOverPkgSection(provider),
          const SizedBox(height: 14),
          _buildButton(
            label: "START SCANNING",
            icon: Icons.qr_code_scanner,
            color: _lightBlueButton,
            onPressed: () async {
              final scanProvider = context.read<ScanDataProvider>();
              // ignore: use_build_context_synchronously
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScanningPage(
                    allowMultipleScan: !scanProvider.isLeftOverPkgOff,
                  ),
                ),
              );
              if (mounted) {
                scanProvider.refresh();
              }
            },
          ),
          const SizedBox(height: 10),
          _buildButton(
            label: "ADD",
            icon: Icons.add_circle_outline,
            color: _greenButton,
            onPressed: () async {
              final scanProvider = context.read<ScanDataProvider>();
              // ignore: use_build_context_synchronously
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPrrPage()),
              );
              if (mounted) {
                scanProvider.refresh();
              }
            },
          ),
          const SizedBox(height: 10),
          _buildButton(
            label: "NEXT",
            icon: Icons.skip_next,
            color: _lightBlueButton,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LoadingSummaryDetailPage(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildButton(
            label: "EXIT",
            icon: Icons.exit_to_app,
            color: _greenButton,
            // EXIT goes back to the home (Welcome) screen, the same way the
            // drawer's "Home" item does.
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
    );
  }

  // ---------- Left Over Pkg (label + toggle, left aligned, no card) ----------
  Widget _leftOverPkgSection(ScanDataProvider provider) {
    return Consumer<ScanDataProvider>(
      builder: (context, vm, _) {
        final isOff = vm.isLeftOverPkgOff;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Left Over Pkg",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(color: Colors.black38, offset: Offset(0, 1)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: vm.toggleLeftOverPkg,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 92,
                height: 36,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isOff
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 4),
                  ],
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: isOff
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        isOff ? "OFF" : "ON",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------- Shared button builder (small, compact) ----------
  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

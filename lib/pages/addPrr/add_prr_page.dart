import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/pages/addPrr/add_prr_provider.dart';
import 'package:flutter_application_1/services/load_capacity.dart';
import 'package:flutter_application_1/utils/booking_date.dart';
import 'package:flutter_application_1/widgets/pms_alert.dart';
import 'package:flutter_application_1/widgets/pms_appbar.dart';
import 'package:provider/provider.dart';

/// "Add PWB/PRR" screen — GUI only (MVVM View).
/// Boxed Railway-style form, same style as the Loading Summary Detail page.
class AddPrrPage extends StatefulWidget {
  const AddPrrPage({super.key});

  @override
  State<AddPrrPage> createState() => _AddPrrPageState();
}

class _AddPrrPageState extends State<AddPrrPage> {

  // PRR No: numbers only, at most 10 digits.
  static final List<TextInputFormatter> _prrNoFormatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ];

  // Station codes: letters only, at most 4, always stored in capitals.
  static final List<TextInputFormatter> _stationCodeFormatters = [
    TextInputFormatter.withFunction(
      (oldValue, newValue) => newValue.copyWith(
        text: newValue.text.toUpperCase(),
        selection: newValue.selection,
      ),
    ),
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
    LengthLimitingTextInputFormatter(4),
  ];

  // Shared design system (single source of truth).
  static const Color _bgLight = const Color(0xFFF5F7F8);
  static const Color _labelGrey = Colors.grey;
  static const Color _red = const Color(0xFFD32F2F);
  static const Color _valueBlack = const Color(0xFF111111);
  static const Color _green = const Color(0xFF2E7D32);
  static const Color _blue = const Color(0xFF1565C0);

  // Field and button heights match Loading Summary Detail so the two forms
  // share one vertical rhythm.
  static const double _fieldHeight = 40;
  static const double _buttonHeight = 46;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddPrrProvider>();

    return Scaffold(
      backgroundColor: _bgLight,
      // Shared app bar - same design as every other page in the app.
      appBar: const PMSAppBar(title: "Add PWB/PRR", showBackButton: true),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Plain light background - the IR watermark was removed here.
          const DecoratedBox(decoration: BoxDecoration(color: _bgLight)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _searchSection(provider, context),
                  const SizedBox(height: 18),
                  _formSection(provider),
                  const SizedBox(height: 22),
                  _bottomButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Search section (red bordered box + OVERLAPPING SEARCH below) ----------

  /// Runs the searchPwbLoad service and reports the outcome.
  Future<void> _runSearch(BuildContext context) async {
    final provider = context.read<AddPrrProvider>();

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final result = await provider.searchPwbLoad();
    if (!context.mounted) return;

    final error = provider.searchError;
    if (error.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (result == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.hasRows
              ? "Search done: ${result.rows.length} record(s) found."
              : "Search done. Server replied without a record list.",
        ),
      ),
    );
  }

  Widget _searchSection(AddPrrProvider provider, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFCFD8DC), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _boxInput(
                  "PRR No.",
                  hint: "Enter PRR No.",
                  required: true,
                  inputFormatters: _prrNoFormatters,
                  controller: provider.prrNoController,
                ),
                const SizedBox(height: 10),
                _formRow([
                  _boxInput(
                    "Source Stn Code",
                    hint: "Enter Source Stn Code",
                    required: true,
                    inputFormatters: _stationCodeFormatters,
                    controller: provider.srcStnCodeController,
                  ),
                  _boxInput(
                    "Dest Stn Code",
                    hint: "Enter Dest Stn Code",
                    required: true,
                    inputFormatters: _stationCodeFormatters,
                    controller: provider.destStnCodeController,
                  ),
                ]),
              ],
            ),
          ),
          SizedBox(height: 14),
          SizedBox(
            height: _buttonHeight,
            child: ElevatedButton.icon(
              onPressed: provider.isSearching
                  ? null
                  : () => _runSearch(context),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.search, color: Colors.white, size: 22),
              label: const Text(
                "SEARCH",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Boxed form (same style as Loading Summary Detail) ----------
  Widget _formSection(AddPrrProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _boxDropdown(
            "Item Type",
            value: provider.itemType,
            hint: "Select",
            items: AddPrrProvider.itemTypesForPrr(
              provider.pwbPrrNoController.text,
            ),
            onChanged: provider.setItemType,
            display: AddPrrProvider.itemTypeLabel,
          ),
          const SizedBox(height: 10),
          _boxDropdown(
            "Booking Type",
            value: provider.bookingType,
            items: AddPrrProvider.bookingTypes,
            onChanged: provider.setBookingType,
          ),
          const SizedBox(height: 10),
          _boxInput(
            "PWB/PRR No",
            hint: "Enter PWB/PRR No",
            required: true,
            inputFormatters: _prrNoFormatters,
            controller: provider.pwbPrrNoController,
          ),
          const SizedBox(height: 10),
          _formRow([
            _boxInput(
              "Src Stn",
              hint: "Enter Src Stn",
              required: true,
              inputFormatters: _stationCodeFormatters,
              controller: provider.srcStnController,
            ),
            _boxInput(
              "Dest Stn",
              hint: "Enter Dest Stn",
              required: true,
              inputFormatters: _stationCodeFormatters,
              controller: provider.destStnController,
            ),
          ]),
          const SizedBox(height: 10),
          _formRow([
            _boxInput(
              "Booking Date",
              hint: "dd-MMM-yyyy HH:mm",
              required: true,
              controller: provider.bookingDateController,
              onEditingComplete: provider.normalizeBookingDate,
              suffixIcon: const Icon(Icons.calendar_month, color: _labelGrey),
              readOnly: true,
              onTap: () async {
              final prov = context.read<AddPrrProvider>();
              await _pickBookingDate(context, prov);
              if (!mounted) return;
            },
            ),
            _boxInput(
              "Fare",
              hint: "Enter Fare",
              controller: provider.fareController,
            ),
          ]),
          const SizedBox(height: 10),
          _boxDouble(
            "Bkd/Ld Pkg",
            "Bkd Pkg",
            "Ld Pkg",
            leftController: provider.bkdPkgController,
            rightController: provider.ldPkgController,
          ),
          const SizedBox(height: 10),
          _boxDouble(
            "Bkd/Ld Wt (in kg)",
            "Bkd Wt",
            "Ld Wt",
            leftController: provider.bkdWtController,
            rightController: provider.ldWtController,
          ),
          const SizedBox(height: 10),
          _boxDropdown(
            "Comodity Type",
            value: provider.comodityType,
            hint: "Select",
            items: AddPrrProvider.comodityTypes,
            onChanged: provider.setComodityType,
            display: AddPrrProvider.comodityLabel,
          ),
          const SizedBox(height: 10),
          _formRow([
            _boxDropdown(
              "Pkg Condn",
              value: provider.pkgCondn,
              hint: "Select",
              items: provider.pkgCondnCodes,
              onChanged: provider.setPkgCondn,
              display: provider.pkgCondnLabel,
            ),
            _boxDropdown(
              "Pkg Desc",
              value: provider.pkgDesc,
              hint: "Select",
              items: provider.pkgDescList,
              onChanged: provider.setPkgDesc,
              display: provider.pkgDescLabel,
            ),
          ]),
          const SizedBox(height: 10),
          _boxInput(
            "Remarks",
            hint: "Enter Remarks",
            controller: provider.remarksController,
          ),
          const SizedBox(height: 10),
          _boxInput(
            "Rack No",
            hint: "Enter Rack No",
            controller: provider.rackNoController,
          ),
        ],
      ),
    );
  }

  // ---------- Boxed field helpers (same as Loading Summary Detail) ----------

  // Grey bold label on top (with optional single red asterisk).
  // Label casing matches Loading Summary Detail: sentence case, not SHOUTING.
  Widget _boxLabel(String text, {bool isRequired = false}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text),
          if (isRequired)
            const TextSpan(
              text: " *",
              style: TextStyle(color: _red, fontSize: 15),
            ),
        ],
      ),
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
  Widget _boxField({required Widget child}) {
    return Container(
      height: _fieldHeight,
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

  Widget _boxInput(
    String label, {
    String hint = "",
    bool required = false,
    List<TextInputFormatter>? inputFormatters,
    TextEditingController? controller,
    VoidCallback? onEditingComplete,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _boxLabel(label, isRequired: required),
        const SizedBox(height: 4),
        _boxField(
          child: TextFormField(
            controller: controller,
            inputFormatters: inputFormatters,
            onEditingComplete: onEditingComplete,
            readOnly: readOnly,
            onTap: onTap,
            style: const TextStyle(color: _valueBlack, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _boxDropdown(
    String label, {
    String? value,
    String hint = "",
    required List<String> items,
    ValueChanged<String>? onChanged,
    String Function(String)? display,
  }) {
    String shown(String v) => display?.call(v) ?? v;
    final current = items.contains(value ?? "") ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _boxLabel(label, isRequired: true),
        const SizedBox(height: 4),
        _boxField(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              isExpanded: true,
              hint: Text(
                hint,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              icon: const Icon(Icons.arrow_drop_down, color: _labelGrey, size: 24),
              style: const TextStyle(color: _valueBlack, fontSize: 15),
              items: [
                for (final it in items)
                  DropdownMenuItem(
                    value: it,
                    child: Text(shown(it), overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: onChanged == null
                  ? null
                  : (v) {
                      if (v != null) onChanged(v);
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _boxDouble(
    String label,
    String leftHint,
    String rightHint, {
    TextEditingController? leftController,
    TextEditingController? rightController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _boxLabel(label, isRequired: true),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _boxField(
                child: TextFormField(
                  controller: leftController,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: _valueBlack, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: leftHint,
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _boxField(
                child: TextFormField(
                  controller: rightController,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: _valueBlack, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: rightHint,
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------- Bottom buttons: SAVE / RESET / CANCEL (full-width stack like Scan Data) ----------
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    bool outlined = false,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: _buttonHeight,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onPressed ?? () {},
              icon: Icon(icon, size: 20, color: color),
              label: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
                side: BorderSide(color: color, width: 1.5),
                shape: const StadiumBorder(),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed ?? () {},
              icon: Icon(icon, color: Colors.white, size: 20),
              label: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
            ),
    );
  }

  /// RESET: asks for confirmation first, then clears the whole form.
  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Reset"),
        content: const Text("Are you sure you want to reset the form?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;
    context.read<AddPrrProvider>().resetForm();
  }

  Widget _bottomButtons(BuildContext context) {
    final provider = context.watch<AddPrrProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildActionButton(
              label: provider.isSaving ? "SAVING..." : "SAVE",
              icon: Icons.check_circle,
              color: _green,
              onPressed: provider.isSaving
                  ? null
                  : () async {
                      // The search API replied WITHOUT a record for this
                      // PWB/PRR, so nothing was auto-filled. Ask the user
                      // whether the entry is still wanted: NO -> nothing
                      // happens, YES -> the required values are checked and
                      // the entry is saved.
                      final currentPrr = provider.pwbPrrNoController.text.trim().isEmpty
                          ? provider.prrNoController.text.trim()
                          : provider.pwbPrrNoController.text.trim();
                      final noServerRecord =
                          provider.noDataForPrr(currentPrr) ||
                          provider.noDataForPrr(
                            provider.prrNoController.text.trim(),
                          );
                      if (noServerRecord) {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text("No Data Found"),
                            content: Text(
                              "The server has no record for PWB/PRR "
                              "$currentPrr.\n\nDo you still want to add it?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text("No"),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text("Yes"),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        // Without a server record the booked / loaded values
                        // have to be entered by the user.
                        if (int.tryParse(
                              provider.bkdPkgController.text.trim(),
                            ) ==
                            null) {
                          if (!context.mounted) return;
                          await PmsAlert.show(
                            context,
                            title: "INVALID BKD PKG",
                            message: "Enter the booked package count.",
                          );
                          return;
                        }
                        if (int.tryParse(
                              provider.ldPkgController.text.trim(),
                            ) ==
                            null) {
                          if (!context.mounted) return;
                          await PmsAlert.show(
                            context,
                            title: "INVALID LD PKG",
                            message: "Enter the loaded package count.",
                          );
                          return;
                        }
                        if (double.tryParse(
                              provider.bkdWtController.text.trim(),
                            ) ==
                            null) {
                          if (!context.mounted) return;
                          await PmsAlert.show(
                            context,
                            title: "INVALID BKD WT",
                            message: "Enter the booked weight.",
                          );
                          return;
                        }
                        if (double.tryParse(
                              provider.ldWtController.text.trim(),
                            ) ==
                            null) {
                          if (!context.mounted) return;
                          await PmsAlert.show(
                            context,
                            title: "INVALID LD WT",
                            message: "Enter the loaded weight.",
                          );
                          return;
                        }
                      }
                      // Booked vs loaded values must match: the loaded
                      // package count / weight can never be more than the
                      // booked ones.
                      final formBkdPkg =
                          int.tryParse(provider.bkdPkgController.text.trim());
                      final formLdPkg =
                          int.tryParse(provider.ldPkgController.text.trim());
                      final formBkdWt =
                          double.tryParse(
                            provider.bkdWtController.text.trim(),
                          );
                      final formLdWt =
                          double.tryParse(
                            provider.ldWtController.text.trim(),
                          );
                      if (formBkdPkg != null &&
                          formBkdPkg > 0 &&
                          formLdPkg != null &&
                          formLdPkg > formBkdPkg) {
                        if (!context.mounted) return;
                        await PmsAlert.show(
                          context,
                          title: "INVALID LD PKG",
                          message:
                              "Loaded package count ($formLdPkg) cannot exceed "
                              "the booked package count ($formBkdPkg).",
                        );
                        return;
                      }
                      if (formBkdWt != null &&
                          formBkdWt > 0 &&
                          formLdWt != null &&
                          formLdWt > formBkdWt) {
                        if (!context.mounted) return;
                        await PmsAlert.show(
                          context,
                          title: "INVALID LD WT",
                          message:
                              "Loaded weight (${formLdWt.toStringAsFixed(2)} kg) "
                              "cannot exceed the booked weight "
                              "(${formBkdWt.toStringAsFixed(2)} kg).",
                        );
                        return;
                      }
                      // Vehicle capacity check: this entry's loaded weight
                      // plus the weight already loaded in the vehicle must
                      // not exceed the capacity (e.g. FCFSLR 3.9 T = 3900 kg).
                      final ldWt =
                          double.tryParse(
                            provider.ldWtController.text.trim(),
                          ) ??
                          0;
                      final capacityKg = await LoadCapacity.capacityKg();
                      if (capacityKg != null) {
                        final total =
                            await LoadCapacity.loadedWeightKg() + ldWt;
                        if (total > capacityKg) {
                          if (!context.mounted) return;
                          await PmsAlert.show(
                            context,
                            title: "VEHICLE CAPACITY EXCEEDED",
                            message: LoadCapacity.capacityMessage(
                              totalKg: total,
                              capacityKg: capacityKg,
                            ),
                          );
                          return;
                        }
                      }
                      if (!context.mounted) return;
                      final error = await provider.saveForm();
                      if (!context.mounted) return;
                      if (error == null) {
                        // Saved — go back to the Scan Data page, which
                        // reloads its table and shows the new row.
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              backgroundColor: _green,
                              content: Text("Saved to local DB successfully."),
                            ),
                          );
                        provider.resetForm();
                        Navigator.pop(context);
                        return;
                      }
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            backgroundColor: _red,
                            content: Text(error),
                          ),
                        );
                    },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildActionButton(
              label: "RESET",
              icon: Icons.refresh,
              color: _blue,
              onPressed: () => _confirmReset(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBookingDate(BuildContext context, AddPrrProvider provider) async {
    final now = DateTime.now();
    DateTime initial = now;
    final parsed = BookingDate.tryParse(provider.bookingDateController.text);
    if (parsed != null) initial = parsed;

    if (!mounted) return;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!mounted) return;
    provider.bookingDateController.text = BookingDate.format(picked);
    if (mounted) setState(() {});
  }
}


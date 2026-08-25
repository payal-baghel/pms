import 'package:flutter/material.dart';

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

  String? selectedVehicleType;

  final List<String> vehicleTypes = [
    "FCFSLR-4T",
    "FCRSLR-4T",
    "SCFSLR-4T",
    "SCRSLR-4T",
    "VPH-24T",
  ];

  @override
  void dispose() {
    scheduledDepController.dispose();
    var trainNoController;
    trainNoController.dispose();
    actualLoadController.dispose();
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
      selectedVehicleType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController? trainNoController;
    return Scaffold(
      appBar: AppBar(title: const Text("Loading"), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              // BOX
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          "Loading Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Scheduled Departure
                      TextFormField(
                        controller: scheduledDepController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Scheduled Departure & Time",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.event),
                        ),
                        onTap: pickScheduledDeparture,
                        validator: (value) => value!.isEmpty
                            ? "Select Scheduled Departure"
                            : null,
                      ),

                      const SizedBox(height: 15),

                      // Vehicle Type
                      DropdownButtonFormField<String>(
                        value: selectedVehicleType,
                        decoration: const InputDecoration(
                          labelText: "Vehicle Type",
                          border: OutlineInputBorder(),
                        ),
                        items: vehicleTypes.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedVehicleType = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? "Select Vehicle Type" : null,
                      ),

                      const SizedBox(height: 15),

                      // Train Number
                      TextFormField(
                        controller: trainNoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Train Number",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.train),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Enter Train Number" : null,
                      ),

                      const SizedBox(height: 15),

                      // Actual Load Date & Time
                      TextFormField(
                        controller: actualLoadController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Actual Load Date & Time",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_month),
                        ),
                        onTap: pickActualLoadDate,
                        validator: (value) =>
                            value!.isEmpty ? "Select Actual Load Date" : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        "Submit",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: clearForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/borrower.dart';
import '../providers/borrower_provider.dart';
import '../services/local_storage_service.dart';

class AddBorrowerScreen extends StatefulWidget {
  const AddBorrowerScreen({super.key});

  @override
  _AddBorrowerScreenState createState() => _AddBorrowerScreenState();
}

class _AddBorrowerScreenState extends State<AddBorrowerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  XFile? _image;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  final LocalStorageService _localStorageService = LocalStorageService();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
      _imageBytes = await pickedFile.readAsBytes();
      setState(() {});
    }
  }

  Future<void> _saveBorrower() async {
    if (_formKey.currentState!.validate()) {
      String id = const Uuid().v4();
      String? profilePicturePath;
      if (_image != null) {
        profilePicturePath = await _localStorageService.saveProfilePicture(id, _image!);
      }
      Borrower borrower = Borrower(
        id: id,
        name: _nameController.text,
        mobileNumber: _mobileController.text,
        profilePicturePath: profilePicturePath,
        bankName: _bankNameController.text,
        accountNumber: _accountNumberController.text,
        accountHolderName: _accountHolderNameController.text,
        branchName: _branchNameController.text,
      );
      await Provider.of<BorrowerProvider>(context, listen: false).addBorrower(borrower);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Borrower'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                  child: _imageBytes == null ? const Icon(Icons.camera_alt, size: 50) : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'Mobile Number'),
                validator: (value) => value!.isEmpty ? 'Please enter a mobile number' : null,
              ),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(labelText: 'Bank Name'),
                validator: (value) => value!.isEmpty ? 'Please enter bank name' : null,
              ),
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(labelText: 'Account Number'),
                validator: (value) => value!.isEmpty ? 'Please enter account number' : null,
              ),
              TextFormField(
                controller: _accountHolderNameController,
                decoration: const InputDecoration(labelText: 'Account Holder Name'),
                validator: (value) => value!.isEmpty ? 'Please enter account holder name' : null,
              ),
              TextFormField(
                controller: _branchNameController,
                decoration: const InputDecoration(labelText: 'Branch Name'),
                validator: (value) => value!.isEmpty ? 'Please enter branch name' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveBorrower,
                child: const Text('Save Borrower'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
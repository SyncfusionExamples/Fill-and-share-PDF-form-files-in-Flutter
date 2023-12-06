import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(MaterialApp(
    title: 'Syncfusion PDF Viewer',
    debugShowCheckedModeBanner: false,
    home: PdfFormFilling(),
  ));
}

/// Represents the SfPdfViewer widget loaded with form document
class PdfFormFilling extends StatefulWidget {
  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<PdfFormFilling> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  List<PdfFormField>? _formFields;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Form'),
      ),
      body: SfPdfViewer.asset(
        'assets/registration_form.pdf',
        key: _pdfViewerKey,
        controller: _pdfViewerController,
        onFormFieldFocusChange: _onFormFieldFocusChange,
        onDocumentLoaded: _onDocumentLoaded,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _validateAndShareFormData();
        },
        label: const Text('Share', style: TextStyle(fontSize: 20)),
        icon: const Icon(Icons.share),
      ),
    );
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    _formFields = _pdfViewerController.getFormFields();
  }

  /// Handle focus change on the DOB field to display DatePicker
  Future<void> _onFormFieldFocusChange(
      PdfFormFieldFocusChangeDetails details) async {
    final PdfFormField formField = details.formField;
    if (details.hasFocus) {
      if (formField is PdfTextFormField && formField.name == 'dob') {
        final DateTime? selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );

        if (selectedDate != null) {
          formField.text =
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
        }

        FocusManager.instance.primaryFocus?.unfocus();
      }
    }
  }

  /// Perform validations on the form data filled and share them externally
  Future<void> _validateAndShareFormData() async {
    final List<String> errors = <String>[];
    for (final PdfFormField formField in _formFields!) {
      if (formField is PdfTextFormField) {
        if (formField.name == 'name') {
          if (formField.text.isEmpty) {
            errors.add('Name is required.');
          } else if (formField.text.length < 3) {
            errors.add('Name should be atleast 3 characters.');
          } else if (formField.text.length > 30) {
            errors.add('Name should not exceed 30 characters.');
          } else if (formField.text.contains(RegExp(r'[0-9]'))) {
            errors.add('Name should not contain numbers.');
          } else if (formField.text
              .contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
            errors.add('Name should not contain special characters.');
          }
        }
        if (formField.name == 'dob') {
          if (formField.text.isEmpty) {
            errors.add('Date of birth is required.');
          } else if (!RegExp(r'^\d{1,2}\/\d{1,2}\/\d{4}$')
              .hasMatch(formField.text)) {
            errors.add('Date of birth should be in dd/mm/yyyy format.');
          }
        }
        if (formField.name == 'email') {
          if (formField.text.isEmpty) {
            errors.add('Email is required.');
          }
          // Email regex comparison
          else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
              .hasMatch(formField.text)) {
            errors.add('Email should be in correct format.');
          }
        }
      } else if (formField is PdfListBoxFormField) {
        if (formField.selectedItems == null ||
            formField.selectedItems!.isEmpty) {
          errors.add('Please select atleast one course.');
        }
      } else if (formField is PdfSignatureFormField) {
        if (formField.signature == null) {
          errors.add('Please sign the document.');
        }
      }
    }

    if (errors.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: SizedBox(
              height: 100,
              width: 100,
              child: ListView.builder(
                itemCount: errors.length,
                itemBuilder: (_, int index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(errors[index]),
                  );
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      _shareForm();
    }
  }

  /// Share the Form externally via platform's share dialog
  Future<void> _shareForm() async {
    List<int> savedBytes = await _pdfViewerController.saveDocument();
    String dir = (await getApplicationCacheDirectory()).path;

    // Save the temporary file in the cache directory
    File('$dir/workshop_registration.pdf').writeAsBytesSync(savedBytes);

    List<XFile> files = [
      XFile('$dir/workshop_registration.pdf', mimeType: 'application/pdf'),
    ];

    // Share the file
    await Share.shareXFiles(files, subject: 'Form document shared successfully.');

    // Remove the file from cache directory
    File('$dir/workshop_registration.pdf').deleteSync();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../i18n/i18n.dart';
import '../../../../utils/analyze_csv_file.dart';
import '../../../../utils/config.dart';
import '../../../../utils/email.dart';
import '../../../../utils/select_csv_file.dart';
import '../../../../utils/snackbar.dart';
import '../../../../widgets/component/component_build_context.dart';
import '../../../../widgets/component/component_life_cycle_listener.dart';
import '../../../../widgets/import/import_state.dart';
import '../../../import_csv/data/csv_deck.dart';
import 'import_csv_component.dart';
import 'import_csv_view_model.dart';

/// BLoC for the [ImportCSVComponent].
@injectable
class ImportCSVBloc with ComponentLifecycleListener, ComponentBuildContext {
  Stream<ImportCSVViewModel>? _viewModel;
  Stream<ImportCSVViewModel>? get viewModel => _viewModel;

  final _filePath = BehaviorSubject<String?>.seeded(null);
  final _deck = BehaviorSubject<CSVDeck?>.seeded(null);
  final _importState =
      BehaviorSubject<ImportState>.seeded(ImportState.showInstructions);

  Stream<ImportCSVViewModel> createViewModel() {
    if (_viewModel != null) {
      return _viewModel!;
    }

    return _viewModel = Rx.combineLatest3(
      _importState,
      _filePath,
      _deck,
      _createViewModel,
    );
  }

  ImportCSVViewModel _createViewModel(
    ImportState importState,
    String? filePath,
    CSVDeck? deck,
  ) {
    return ImportCSVViewModel(
      importState: importState,
      importDeck: deck,
      filePath: filePath,
      onSelectFileTap: _showSelectFileDialog,
      analyzeFile: _analyzeFile,
      onOpenEmailAppTap: _handleOpenEmailAppTap,
      importOverviewCallback: () => _importState.add(ImportState.showProgress),
      importCallback: () => _importState.add(ImportState.importFinished),
    );
  }

  @override
  void dispose() {
    _filePath.close();
    _deck.close();
    _importState.close();
    super.dispose();
  }

  Future<void> _showSelectFileDialog() async {
    final filePath = await selectCSVFile(context);
    if (filePath == null) {
      return;
    }

    _importState.add(ImportState.analyzeFile);
    _filePath.add(filePath);
  }

  Future<void> _analyzeFile(
    void Function(String, [AsyncCallback]) errorCallback,
  ) async {
    final deck = await catchCSVExceptions(
      () => analyzeCSVFile(_filePath.value!, context),
      context,
      errorCallback,
      _handleOpenEmailAppTap,
    );
    if (deck == null) {
      return;
    }

    _importState.add(ImportState.showDataOverview);
    _deck.add(deck);
  }

  Future<void> _handleOpenEmailAppTap() async {
    try {
      await openEmailAppWithTemplate(
        email: supportEmail,
        subject: 'Problems importing an CSV file',
        body: 'Hey Space Team,\n\n'
            "I'm having trouble analyzing my CSV file. "
            'I have attached the CSV file.\n\n'
            'Best regards',
      );
    } on Exception {
      ScaffoldMessenger.of(context).showErrorSnackBar(
        theme: Theme.of(context),
        text: S.of(context).errorSendEmailToSupportText(supportEmail),
      );
    }
  }
}

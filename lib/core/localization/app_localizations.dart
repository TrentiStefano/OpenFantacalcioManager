import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('it'));

  void setLocale(Locale newLocale) {
    state = newLocale;
  }

  void toggleLocale() {
    state = state.languageCode == 'it' ? const Locale('en') : const Locale('it');
  }
}

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('it'));
  }

  static const _localizedValues = <String, Map<String, String>>{
    'it': {
      'app_title': 'Open Fantacalcio Manager',
      'nav_listone': 'Listone',
      'nav_strategy': 'Strategie',
      'nav_auction': 'Asta Live',
      'nav_my_team': 'La Mia Rosa',
      'nav_setup': 'Setup & Import',
      'nav_settings': 'Impostazioni',

      // Roles
      'role_P': 'Portieri',
      'role_D': 'Difensori',
      'role_C': 'Centrocampisti',
      'role_A': 'Attaccanti',
      'role_P_short': 'P',
      'role_D_short': 'D',
      'role_C_short': 'C',
      'role_A_short': 'A',

      // Columns & Labels
      'player': 'Calciatore',
      'role': 'Ruolo',
      'team': 'Squadra',
      'fvm': 'FVM',
      'qta': 'Qt.A',
      'qti': 'Qt.I',
      'diff': 'Diff.',
      'budget_pct': '% Budget',
      'base_value': 'Valore Base',
      'tier': 'Fascia',
      'favorite': 'Preferito',
      'target_price': 'Prezzo Obiettivo',
      'notes': 'Note',
      'status': 'Stato',
      'purchase_price': 'Val. Acquisto',
      'actions': 'Azioni',

      // Status
      'status_available': 'Disponibile',
      'status_mine': 'Mio',
      'status_others': 'Altri',

      // Live Auction
      'live_auction_title': 'Asta Live Serie A',
      'search_player_hint': 'Cerca calciatore per nome o squadra...',
      'assign_to_me': 'Assegna a me',
      'sold_to_others': 'Venduto ad altri',
      'reset_available': 'Rimetti disponibile',
      'enter_hammer_price': 'Prezzo di chiusura:',
      'credits': 'crediti',
      'confirm': 'Conferma',
      'cancel': 'Annulla',
      'save': 'Salva',
      'edit': 'Modifica',
      'delete': 'Rimuovi',
      'no_player_selected': 'Nessun calciatore selezionato. Cerca o seleziona un giocatore.',

      // Summary & Rosa
      'initial_budget': 'Budget Iniziale',
      'total_spent': 'Totale Speso',
      'remaining_budget': 'Budget Residuo',
      'remaining_slots': 'Slot Rimanenti',
      'total_slots': 'Slot Totali',
      'acquired': 'Acquistati',
      'allocated_budget': 'Budget Allocato',
      'spent': 'Speso',
      'residual': 'Residuo',
      'roster_empty': 'Nessun giocatore acquistato finora. Inizia l\'asta per popolare la rosa!',
      'summary_title': 'Riepilogo Budget & Roster',
      'roster_title': 'Rosa Ufficiale',

      // Strategy & Listone
      'suggest_fvm': 'Suggerisci % da FVM',
      'export_excel': 'Esporta Excel (.xlsx)',
      'export_csv': 'Esporta CSV (.csv)',
      'import_quotazioni': 'Importa Quotazioni (.xlsx / .csv)',
      'filter_all_roles': 'Tutti i ruoli',
      'filter_all_tiers': 'Tutte le fasce',
      'filter_favorites': 'Solo preferiti',
      'filter_available': 'Solo disponibili',
      'players_count': 'calciatori',
      'search': 'Cerca...',

      // Setup
      'setup_title': 'Configurazione Campionato & Import',
      'setup_subtitle': 'Importa il listone della stagione e configura budget e slot rosa',
      'classic_mode': 'Modalità Classic',
      'mantra_mode': 'Modalità Mantra',
      'budget_credits': 'Budget iniziale (crediti)',
      'slots_per_role': 'Slot rosa per ruolo',
      'allocations_per_role': 'Budget allocato per ruolo (crediti)',
      'save_settings': 'Salva Configurazione',
      'load_sample_file': 'Carica Esempio Stagione 2026/27',
      'file_imported_success': 'File importato con successo!',
      'import_error': 'Errore durante l\'importazione del file',
      'reset_season': 'Azzera Stagione / Nuovo Campionato',
      'reset_warning': 'Attenzione: tutti i dati della stagione corrente, le note e gli acquisti verranno cancellati.',
      'language': 'Lingua',
      'theme': 'Tema',
      'theme_light': 'Chiaro',
      'theme_dark': 'Scuro',
      'theme_system': 'Sistema',
    },
    'en': {
      'app_title': 'Open Fantacalcio Manager',
      'nav_listone': 'Master Board',
      'nav_strategy': 'Strategy',
      'nav_auction': 'Live Auction',
      'nav_my_team': 'My Roster',
      'nav_setup': 'Setup & Import',
      'nav_settings': 'Settings',

      // Roles
      'role_P': 'Goalkeepers',
      'role_D': 'Defenders',
      'role_C': 'Midfielders',
      'role_A': 'Forwards',
      'role_P_short': 'GK',
      'role_D_short': 'DEF',
      'role_C_short': 'MID',
      'role_A_short': 'FWD',

      // Columns & Labels
      'player': 'Player',
      'role': 'Role',
      'team': 'Club',
      'fvm': 'FVM',
      'qta': 'Qt.A',
      'qti': 'Qt.I',
      'diff': 'Diff.',
      'budget_pct': '% Budget',
      'base_value': 'Base Value',
      'tier': 'Tier',
      'favorite': 'Favorite',
      'target_price': 'Target Price',
      'notes': 'Notes',
      'status': 'Status',
      'purchase_price': 'Cost',
      'actions': 'Actions',

      // Status
      'status_available': 'Available',
      'status_mine': 'Mine',
      'status_others': 'Others',

      // Live Auction
      'live_auction_title': 'Live Auction Draft',
      'search_player_hint': 'Search player by name or team...',
      'assign_to_me': 'Assign to me',
      'sold_to_others': 'Sold to others',
      'reset_available': 'Make available',
      'enter_hammer_price': 'Hammer price:',
      'credits': 'credits',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Remove',
      'no_player_selected': 'No player selected. Search or select a player.',

      // Summary & Rosa
      'initial_budget': 'Initial Budget',
      'total_spent': 'Total Spent',
      'remaining_budget': 'Remaining Budget',
      'remaining_slots': 'Remaining Slots',
      'total_slots': 'Total Slots',
      'acquired': 'Bought',
      'allocated_budget': 'Allocated Budget',
      'spent': 'Spent',
      'residual': 'Residual',
      'roster_empty': 'No players acquired yet. Start the draft to fill your roster!',
      'summary_title': 'Budget & Roster Summary',
      'roster_title': 'Official Roster',

      // Strategy & Listone
      'suggest_fvm': 'Suggest % from FVM',
      'export_excel': 'Export Excel (.xlsx)',
      'export_csv': 'Export CSV (.csv)',
      'import_quotazioni': 'Import Price List (.xlsx / .csv)',
      'filter_all_roles': 'All roles',
      'filter_all_tiers': 'All tiers',
      'filter_favorites': 'Favorites only',
      'filter_available': 'Available only',
      'players_count': 'players',
      'search': 'Search...',

      // Setup
      'setup_title': 'League Setup & Import',
      'setup_subtitle': 'Import the season price list and configure budget and roster slots',
      'classic_mode': 'Classic Mode',
      'mantra_mode': 'Mantra Mode',
      'budget_credits': 'Initial budget (credits)',
      'slots_per_role': 'Roster slots per role',
      'allocations_per_role': 'Allocated budget per role (credits)',
      'save_settings': 'Save Configuration',
      'load_sample_file': 'Load 2026/27 Sample Fixture',
      'file_imported_success': 'File imported successfully!',
      'import_error': 'Error importing file',
      'reset_season': 'Reset Season / Start New League',
      'reset_warning': 'Warning: all current season data, notes, and purchases will be permanently erased.',
      'language': 'Language',
      'theme': 'Theme',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'theme_system': 'System',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['it']?[key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['it', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/dnl_data_aggregator.dart';
import '../widgets/dnl_label_widget.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DNLLabelDisplayScreen extends StatefulWidget {
  final String appName;

  const DNLLabelDisplayScreen({super.key, required this.appName});

  @override
  State<DNLLabelDisplayScreen> createState() => _DNLLabelDisplayScreenState();
}

class _DNLLabelDisplayScreenState extends State<DNLLabelDisplayScreen> {
  final DNLDataAggregator _aggregator = DNLDataAggregator();

  Map<String, dynamic>? _aggregatedData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAggregatedData();
  }

  Future<void> _loadAggregatedData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Uses aggregateAppData from DNLDataAggregator
      final data = await _aggregator.aggregateAppData(widget.appName);

      setState(() {
        _aggregatedData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _printDNLLabel() async {
    if (_aggregatedData == null) return;

    try {
      // Show a loading dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          const Text('Generating PDF...'),
                        ],
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
      );

      // Generate PDF
      final pdf = await _generatePDF();

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Print or save
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to generate PDF: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _downloadPDF() async {
    if (_aggregatedData == null) return;

    try {
      final pdf = await _generatePDF();

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: '${widget.appName}_DNL_Report.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to download PDF: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  pw.Document _generatePDF() {
    final pdf = pw.Document();
    final data = _aggregatedData!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 2, color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(16),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Header
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: const pw.BoxDecoration(color: PdfColors.teal),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        // App icon placeholder
                        pw.Container(
                          width: 48,
                          height: 48,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              data['app_name'] != null &&
                                      data['app_name'].toString().isNotEmpty
                                  ? data['app_name'][0].toString().toUpperCase()
                                  : 'A',
                              style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.teal,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 16),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              data['app_name'] ?? 'Unknown App',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Digital Nutrition Label Report',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                        pw.Spacer(),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(20),
                          ),
                          child: pw.Text(
                            data['os_type'] ?? 'Android',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // DNL Content
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Title
                        pw.Text(
                          'Digital Nutrition Facts',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Divider(thickness: 2, color: PdfColors.grey800),
                        pw.SizedBox(height: 8),

                        // App details
                        _buildPDFRow('Version:', data['device_model'] ?? 'N/A'),
                        _buildPDFRow(
                          'Evaluated on:',
                          data['created_at'] ?? 'N/A',
                        ),
                        _buildPDFRow('For ages', data['age_rating'] ?? 'N/A'),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Based on ${data['submission_count'] ?? 1} submissions from ${data['tester_count'] ?? 1} testers',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                        pw.SizedBox(height: 16),

                        // Average Daily Interruptions
                        pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey200,
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Average Daily Interruptions',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                data['avg_interruptions']?.toString() ?? '0',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 16),

                        // Privacy Section
                        pw.Text(
                          'Privacy',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Divider(thickness: 1),
                        pw.SizedBox(height: 8),

                        // Permissions
                        _buildPDFSection(
                          'Permissions Requested',
                          data['permissions_asked'] is List
                              ? (data['permissions_asked'] as List)
                                    .map((e) => e.toString())
                                    .toList()
                              : [],
                        ),
                        pw.SizedBox(height: 12),

                        // Data Linked
                        _buildPDFSection(
                          'Data Handling and Sharing',
                          data['data_linked'] is List
                              ? (data['data_linked'] as List)
                                    .map((e) => e.toString())
                                    .toList()
                              : [],
                        ),
                        pw.SizedBox(height: 16),

                        // User Rights Section
                        pw.Text(
                          'User Rights',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Divider(thickness: 1),
                        pw.SizedBox(height: 8),

                        _buildPDFRow('Ads Opt-Out', 'Varies by app'),
                        _buildPDFRow('Account Deletion', 'Check app settings'),

                        pw.SizedBox(height: 16),

                        // Additional Info
                        pw.Text(
                          'Additional Information',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Divider(thickness: 1),
                        pw.SizedBox(height: 8),

                        if (data['observations'] != null &&
                            data['observations'].toString().isNotEmpty)
                          pw.Text(
                            data['observations'],
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPDFRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFSection(String title, List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$title (${items.length} total)',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        if (items.isEmpty)
          pw.Text(
            'None',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          )
        else
          pw.Wrap(
            spacing: 6,
            runSpacing: 4,
            children: items
                .map(
                  (item) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Text(
                      item,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00796B), Color(0xFF00BFA5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.white, size: 60)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
              ),
          const SizedBox(height: 16),
          Text(
            'Oops!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAggregatedData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              foregroundColor: const Color(0xFF00796B),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final data = _aggregatedData!;

    // FIXED: Wrapped in LayoutBuilder to get available height
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          // FIXED: Made content scrollable
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight, // Ensure minimum height
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // FIXED: Use min size
                children: [
                  // Header section
                  Row(
                    children: [
                      // App icon with gradient border
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF80CBC4), Color(0xFF004D40)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(
                              data['app_name'] != null &&
                                      data['app_name'].toString().isNotEmpty
                                  ? data['app_name'][0].toString().toUpperCase()
                                  : 'A',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00796B),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // App name and description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['app_name'] ?? 'Unknown App',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Digital Nutrition Label Overview',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      // OS Type Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone_android,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              data['os_type'] ?? 'Android',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),

                  const SizedBox(height: 16),

                  // Main DNL Card - FIXED: Removed Expanded, let it size naturally
                  DNLLabelWidget(
                    data: _aggregatedData!,
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        label: const Text(
                          'Back',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _downloadPDF,
                            icon: const Icon(Icons.download),
                            label: const Text('Download PDF'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: const Color(0xFF00796B),
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ).animate().fadeIn().slideX(begin: 0.4),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _printDNLLabel,
                            icon: const Icon(Icons.print, color: Colors.white),
                            label: const Text(
                              'Print',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ).animate().fadeIn().slideX(begin: 0.4),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16), // FIXED: Added bottom padding
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

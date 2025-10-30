import 'package:visionpos/utils/api_config.dart';
import 'package:flutter/material.dart';

class ApiSettingsDialog extends StatefulWidget {
  const ApiSettingsDialog({Key? key}) : super(key: key);

  @override
  State<ApiSettingsDialog> createState() => _ApiSettingsDialogState();
}

class _ApiSettingsDialogState extends State<ApiSettingsDialog> {
  String _selectedEnvironment = ApiConfig.instance.environment;
  final TextEditingController _customUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (_selectedEnvironment == ApiConfig.CUSTOM) {
      _customUrlController.text = ApiConfig.instance.baseUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('API Configuration'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Environment: ${ApiConfig.instance.environment}'),
            Text('Current URL: ${ApiConfig.instance.baseUrl}'),
            const SizedBox(height: 20),
            const Text(
              'Select Environment:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...ApiConfig.availableEnvironments.map(
              (env) => RadioListTile<String>(
                title: Text(_getEnvironmentLabel(env)),
                subtitle: env != ApiConfig.CUSTOM
                    ? Text(ApiConfig.predefinedUrls[env] ?? '')
                    : null,
                value: env,
                groupValue: _selectedEnvironment,
                onChanged: (value) {
                  setState(() {
                    _selectedEnvironment = value!;
                    if (value != ApiConfig.CUSTOM) {
                      _customUrlController.clear();
                    }
                  });
                },
              ),
            ),
            if (_selectedEnvironment == ApiConfig.CUSTOM) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _customUrlController,
                decoration: const InputDecoration(
                  labelText: 'Custom API URL',
                  hintText: 'https://your-api-server.com',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Note: "/api" will be added automatically if not present',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveConfiguration,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  String _getEnvironmentLabel(String env) {
    switch (env) {
      case ApiConfig.LOCAL:
        return 'Local Development';
      case ApiConfig.PRODUCTION:
        return 'Production';
      case ApiConfig.STAGING:
        return 'Staging';
      case ApiConfig.CUSTOM:
        return 'Custom URL';
      default:
        return env;
    }
  }

  Future<void> _saveConfiguration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedEnvironment == ApiConfig.CUSTOM) {
        if (_customUrlController.text.trim().isEmpty) {
          _showErrorDialog('Please enter a custom URL');
          return;
        }
        await ApiConfig.instance.setCustomBaseUrl(
          _customUrlController.text.trim(),
        );
      } else {
        await ApiConfig.instance.setEnvironment(_selectedEnvironment);
      }

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessSnackBar();
      }
    } catch (e) {
      _showErrorDialog('Failed to save configuration: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'API configuration updated to ${ApiConfig.instance.environment}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _customUrlController.dispose();
    super.dispose();
  }
}

// Helper function to show the API settings dialog
void showApiSettingsDialog(BuildContext context) {
  showDialog(context: context, builder: (context) => const ApiSettingsDialog());
}

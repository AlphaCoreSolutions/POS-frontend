import 'package:visionpos/utils/api_config.dart';
import 'package:flutter/material.dart';

class QuickApiSwitcher extends StatelessWidget {
  final VoidCallback? onEnvironmentChanged;

  const QuickApiSwitcher({Key? key, this.onEnvironmentChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.wifi_tethering),
      tooltip: 'Quick API Switch',
      onSelected: (String environment) async {
        try {
          await ApiConfig.instance.setEnvironment(environment);
          if (onEnvironmentChanged != null) {
            onEnvironmentChanged!();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Switched to ${_getEnvironmentName(environment)}'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to switch environment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: ApiConfig.LOCAL,
          child: ListTile(
            leading: Icon(Icons.computer, color: Colors.green),
            title: Text('Local'),
            subtitle: Text('localhost:5001'),
            trailing: ApiConfig.instance.environment == ApiConfig.LOCAL
                ? Icon(Icons.check, color: Colors.green)
                : null,
          ),
        ),
        PopupMenuItem<String>(
          value: ApiConfig.PRODUCTION,
          child: ListTile(
            leading: Icon(Icons.cloud, color: Colors.blue),
            title: Text('Production'),
            subtitle: Text('posapi.alphacorecit.com'),
            trailing: ApiConfig.instance.environment == ApiConfig.PRODUCTION
                ? Icon(Icons.check, color: Colors.green)
                : null,
          ),
        ),
        PopupMenuItem<String>(
          value: ApiConfig.STAGING,
          child: ListTile(
            leading: Icon(Icons.cloud_queue, color: Colors.orange),
            title: Text('Staging'),
            subtitle: Text('staging.alphacorecit.com'),
            trailing: ApiConfig.instance.environment == ApiConfig.STAGING
                ? Icon(Icons.check, color: Colors.green)
                : null,
          ),
        ),
      ],
    );
  }

  String _getEnvironmentName(String environment) {
    switch (environment) {
      case ApiConfig.LOCAL:
        return 'Local Development';
      case ApiConfig.PRODUCTION:
        return 'Production';
      case ApiConfig.STAGING:
        return 'Staging';
      default:
        return environment;
    }
  }
}

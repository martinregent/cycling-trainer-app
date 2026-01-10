import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/gpx_route.dart';
import '../services/gpx_parser.dart';
import 'workout_screen.dart';

class RouteLibraryScreen extends StatefulWidget {
  const RouteLibraryScreen({super.key});

  @override
  State<RouteLibraryScreen> createState() => _RouteLibraryScreenState();
}

class _RouteLibraryScreenState extends State<RouteLibraryScreen> {
  final Box<GPXRoute> _routesBox = Hive.box<GPXRoute>('routes');
  final GPXParserService _parserService = GPXParserService();
  bool _isLoading = false;

  Future<void> _importGPX() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gpx'],
      );

      if (result != null) {
        setState(() {
          _isLoading = true;
        });

        File file = File(result.files.single.path!);
        String xmlContent = await file.readAsString();
        
        // Parse GPX
        final route = await _parserService.parse(
          xmlContent, 
          name: result.files.single.name.replaceAll('.gpx', '')
        );
        
        // Save to Hive
        await _routesBox.add(route);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Parcours importé: ${route.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'import: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _deleteRoute(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le parcours'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce parcours ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _routesBox.deleteAt(index);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _startWorkout(GPXRoute route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutScreen(route: route),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque de Parcours'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _importGPX,
              tooltip: 'Importer GPX',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: _routesBox.listenable(),
              builder: (context, Box<GPXRoute> box, _) {
                if (box.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun parcours',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _importGPX,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Importer un fichier GPX'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final route = box.getAt(index);
                    if (route == null) return const SizedBox.shrink();

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.directions_bike),
                        ),
                        title: Text(route.name),
                        subtitle: Text(
                          '${(route.distance / 1000).toStringAsFixed(1)} km • '
                          '${route.elevationGain.toStringAsFixed(0)}m D+',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                route.isFavorite ? Icons.star : Icons.star_border,
                                color: route.isFavorite ? Colors.orange : null,
                              ),
                              onPressed: () {
                                route.isFavorite = !route.isFavorite;
                                route.save();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteRoute(index),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () => _startWorkout(route),
                              icon: const Icon(Icons.play_arrow, size: 16),
                              label: const Text('Go'),
                            ),
                          ],
                        ),
                        onTap: () => _startWorkout(route),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

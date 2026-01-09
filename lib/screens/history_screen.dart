import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/strava/strava_service.dart';
import '../services/strava/fit_exporter.dart';
import '../models/workout.dart';
import '../repositories/workout_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final WorkoutRepository _repository = WorkoutRepository();
  List<Workout> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() => _isLoading = true);
    try {
      final workouts = await _repository.getAllWorkouts();
      setState(() {
        _workouts = workouts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading workouts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteWorkout(String id) async {
    await _repository.deleteWorkout(id);
    _loadWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkouts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workouts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucune séance enregistrée',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _workouts.length,
                  itemBuilder: (context, index) {
                    final workout = _workouts[index];
                    return Dismissible(
                      key: Key(workout.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Confirmer la suppression"),
                              content: const Text(
                                  "Êtes-vous sûr de vouloir supprimer cette séance ?"),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("Annuler"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text("Supprimer"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        _deleteWorkout(workout.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Séance supprimée')),
                        );
                      },
                      child: WorkoutHistoryCard(workout: workout),
                    );
                  },
                ),
    );
  }
}

class WorkoutHistoryCard extends StatelessWidget {
  final Workout workout;

  const WorkoutHistoryCard({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_bike),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(workout.date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        workout.routeId != null ? 'Parcours' : 'Libre',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.orange),
                      tooltip: 'Partager sur Strava',
                      onPressed: () => _shareToStrava(context, workout),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  context,
                  Icons.timer,
                  workout.formattedDuration,
                  'Durée',
                ),
                _buildStat(
                  context,
                  Icons.straighten,
                  (workout.distance / 1000).toStringAsFixed(1),
                  'km',
                ),
                _buildStat(
                  context,
                  Icons.flash_on,
                  workout.avgPower.toStringAsFixed(0),
                  'W (avg)',
                ),
                _buildStat(
                  context,
                  Icons.favorite,
                  workout.avgHeartRate.toStringAsFixed(0),
                  'BPM (avg)',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String value, String unit) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _shareToStrava(BuildContext context, Workout workout) async {
    final strava = context.read<StravaService>();
    
    // Check authentication
    if (!strava.isAuthenticated) {
      final shouldAuth = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connexion Strava'),
          content: const Text('Vous devez être connecté à Strava pour partager votre séance.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );

      if (shouldAuth == true) {
        try {
          await strava.authenticate();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur auth: $e')),
            );
          }
        }
      }
      return;
    }

    // Proceed to upload
     if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Génération du fichier FIT...')),
      );
    }

    try {
      final fitData = await FITExporter().export(workout);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Envoi vers Strava...')),
        );
      }

      await strava.uploadActivity(
        fitData, 
        'Séance ${DateFormat('dd MMM').format(workout.date)}', 
        'Séance enregistrée avec Cycling Trainer App (Flutter)',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Séance partagée sur Strava avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

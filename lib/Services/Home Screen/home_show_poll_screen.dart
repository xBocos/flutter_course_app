import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_course_app/Services/Home%20Screen/create_poll_screen.dart';
import 'package:flutter_course_app/Services/Home%20Screen/edit_poll_screen.dart';
import 'package:flutter_course_app/Services/AuthServices/signin_screen.dart';
import 'package:page_transition/page_transition.dart';

class HomeShowPollScreen extends StatefulWidget {
  const HomeShowPollScreen({super.key});

  @override
  State<HomeShowPollScreen> createState() => _HomeShowPollScreenState();
}

class _HomeShowPollScreenState extends State<HomeShowPollScreen> {
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Create Poll"),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SigninScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.settings),
            ),
          ],
          bottom: const TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: Colors.orange,
            unselectedLabelColor: Colors.black,
            labelStyle: TextStyle(
              color: Colors.orange,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: "All"),
              Tab(text: "Posted"),
              Tab(text: "Voted"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAllPolls(),
            _buildPostedPolls(),
            _buildVotedPolls(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.fade,
                child: CreatePollScreen(currentUserId: _currentUserId),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildOptionImage(String imageData) {
    if (imageData.isEmpty) {
      return const Icon(
        Icons.image_not_supported,
        size: 50,
        color: Colors.grey,
      );
    }
    if (imageData.startsWith('http')) {
      return Image.network(
        imageData,
        height: 50,
        width: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.image_not_supported,
            size: 50,
            color: Colors.grey,
          );
        },
      );
    }
    try {
      return Image.memory(
        base64Decode(imageData),
        height: 50,
        width: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.image_not_supported,
            size: 50,
            color: Colors.grey,
          );
        },
      );
    } catch (_) {
      return const Icon(
        Icons.image_not_supported,
        size: 50,
        color: Colors.grey,
      );
    }
  }

  Widget _buildPostedPolls() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('polls')
          .where('creatorId', isEqualTo: _currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.orange,
            ),
          );
        }
        final polls = snapshot.data!.docs;
        return polls.isEmpty
            ? const Center(
                child: Text(
                  'No Posted Poll Available',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: polls.length,
                itemBuilder: (context, index) {
                  final poll = polls[index];
                  return _buildPollCard(poll, showUserVote: false);
                },
              );
      },
    );
  }

  Widget _buildAllPolls() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('polls')
          .where('creatorId', isNotEqualTo: _currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.orange,
            ),
          );
        }
        final polls = snapshot.data!.docs;
        return polls.isEmpty
            ? const Center(
                child: Text(
                  'No Poll Available',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: polls.length,
                itemBuilder: (context, index) {
                  final poll = polls[index];
                  return _buildPollCard(poll, showUserVote: true);
                },
              );
      },
    );
  }

  Widget _buildPollCard(DocumentSnapshot poll, {bool showUserVote = false}) {
    final data = poll.data() as Map<String, dynamic>;
    final options = data['options'] as List<dynamic>;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(
                color: Colors.orangeAccent,
                thickness: 1,
                height: 20,
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < options.length; i++) ...[
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 6,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildOptionImage(options[i]['imageUrl'] ?? ''),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              options[i]['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (options[i]['votes'] ?? 0.0) / 10,
                              color: Colors.orange,
                              backgroundColor: Colors.grey[300],
                            ),
                            if (showUserVote &&
                                options[i]['voters'] != null &&
                                (options[i]['voters'] as List).contains(
                                  _currentUserId,
                                ))
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'You voted',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      if (showUserVote)
                        ElevatedButton(
                          onPressed: () {
                            handleVote(poll.id, i, context, _currentUserId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          child: const Text(
                            'vote',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 5),
              if (!showUserVote)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPollScreen(poll: poll),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      label: const Text(
                        'Edit',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                    const SizedBox(width: 5),
                    TextButton.icon(
                      onPressed: () {
                        deletePoll(poll.id, context);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
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

  Widget _buildVotedPolls() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('polls').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.orange,
            ),
          );
        }
        final polls = snapshot.data!.docs;

        final votedPolls = polls.where((poll) {
          final options = poll['options'] as List<dynamic>;
          for (var option in options) {
            if (option['voters'] != null &&
                (option['voters'] as List).contains(_currentUserId)) {
              return true;
            }
          }
          return false;
        }).toList();

        return votedPolls.isEmpty
            ? const Center(
                child: Text(
                  'No Voted Poll Available',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: votedPolls.length,
                itemBuilder: (context, index) {
                  final poll = votedPolls[index];
                  return _buildPollCard(poll, showUserVote: true);
                },
              );
      },
    );
  }

  Future<void> deletePoll(String pollId, BuildContext context) async {
    try {
      DocumentSnapshot pollDoc = await FirebaseFirestore.instance
          .collection('polls')
          .doc(pollId)
          .get();
      if (pollDoc.exists) {
        List<dynamic> options = pollDoc['options'] ?? [];
        for (var option in options) {
          String imageUrl = option['imageUrl'] ?? '';
          if (imageUrl.startsWith('http')) {
            String? filepath = Uri.decodeFull(
              Uri.parse(imageUrl).pathSegments.lastWhere(
                    (element) => element.contains('poll'),
                    orElse: () => '',
                  ),
            );
            if (filepath.isNotEmpty) {
              await FirebaseStorage.instance.ref(filepath).delete();
            }
          }
        }
        await FirebaseFirestore.instance
            .collection('polls')
            .doc(pollId)
            .delete();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poll and associated images deleted successfully'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting poll $e'),
        ),
      );
    }
  }

  Future<void> handleVote(
    String pollId,
    int optionIndex,
    BuildContext context,
    String currentUserId,
  ) async {
    try {
      final pollDoc =
          FirebaseFirestore.instance.collection('polls').doc(pollId);
      final pollSnapshot = await pollDoc.get();
      if (pollSnapshot.exists) {
        final data = pollSnapshot.data() as Map<String, dynamic>;
        final totalVotes = data['total_votes'] ?? 0;
        final options = data['options'] as List<dynamic>;

        for (var option in options) {
          if (option['voters'] != null &&
              (option['voters'] as List).contains(currentUserId)) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You have already voted')),
            );
            return;
          }
        }

        final voters = List<dynamic>.from(options[optionIndex]['voters'] ?? []);
        voters.add(currentUserId);
        options[optionIndex]['voters'] = voters;

        options[optionIndex]['votes'] =
            (options[optionIndex]['votes'] ?? 0) + 1;

        await pollDoc.update({
          'options': options,
          'total_votes': totalVotes + 1,
        });

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote submitted successfully'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit vote $e')),
      );
    }
  }
}

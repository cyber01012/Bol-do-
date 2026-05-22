import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/glass_card.dart';
import '../../ui/widgets/boldo_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedAvatar = '👨‍🔧';
  final List<String> _avatars = ['👨‍🔧', '👩‍🔧', '👷‍♂️', '👷‍♀️', '👤'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['display_name'] ?? '';
        _phoneController.text = data['phone_number'] ?? '';
        _addressController.text = data['address'] ?? '';
        setState(() {
          _selectedAvatar = data['avatar'] ?? '👨‍🔧';
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not authenticated.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'display_name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'avatar': _selectedAvatar,
        'profile_completed': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully! 🎉')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BolDoAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Complete Your Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: BolDoTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Profile completion unlocks full orchestration capabilities.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: BolDoTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Avatar Selection
                  Wrap(
                    spacing: 16,
                    children: _avatars.map((avatar) {
                      final isSelected = _selectedAvatar == avatar;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatar = avatar;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? BolDoTheme.primary.withOpacity(0.2) : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? BolDoTheme.primary : BolDoTheme.textSecondary.withOpacity(0.3),
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Text(avatar, style: const TextStyle(fontSize: 32)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),

                  // Profile Form
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: BolDoTheme.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Display Name',
                            labelStyle: const TextStyle(color: BolDoTheme.textSecondary),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: BolDoTheme.textSecondary.withOpacity(0.5)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: BolDoTheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: BolDoTheme.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: const TextStyle(color: BolDoTheme.textSecondary),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: BolDoTheme.textSecondary.withOpacity(0.5)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: BolDoTheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _addressController,
                          style: const TextStyle(color: BolDoTheme.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Address',
                            labelStyle: const TextStyle(color: BolDoTheme.textSecondary),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: BolDoTheme.textSecondary.withOpacity(0.5)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: BolDoTheme.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BolDoTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

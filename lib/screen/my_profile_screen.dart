import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wonmore_money_book/dialog/custom_confirm_dialog.dart';
import 'package:wonmore_money_book/model/budget_model.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/widget/common_app_bar.dart';

class MyInfoScreen extends StatefulWidget {
  const MyInfoScreen({super.key});

  @override
  State<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends State<MyInfoScreen> {
  File? profileImage;
  bool? isInterProfile;
  bool? isProfileDelete;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();
  // 이미지 업로드 / 닉네임 수정 상태
  // 초기값은 Provider에서 받아옴

  @override
  void initState() {
    super.initState();
    isInterProfile = false;
    isProfileDelete = false;
    _nameController.text = context.read<UserProvider>().myInfo?.name ?? '';
    _groupController.text = context.read<UserProvider>().myInfo?.groupName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final myInfo = userProvider.myInfo;
    final hasProfile = myInfo!.isProfile ?? false;

    return Scaffold(
      appBar: CommonAppBar(isMainScreen: false, label: '내 정보'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. 프로필 아바타
            GestureDetector(
              onTap: () {
                showBottomSheetProfile(
                  hasProfile || isInterProfile!
                );
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: isInterProfile!
                        ? FileImage(profileImage!) // File 타입 (null 체크는 위에서 하거나 ! 사용)
                        : (hasProfile ? NetworkImage(myInfo.profileUrl ?? '') : null),
                    child: !hasProfile && !isInterProfile! ? Icon(Icons.person, color: Colors.black, size: 40) : null,
                  ),
                  const SizedBox(height: 16),
                  Text('프로필 사진 변경'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. 이메일 (표시만)
            TextFormField(
              initialValue: myInfo.email,
              enabled: false,
              decoration: const InputDecoration(labelText: '이메일'),
            ),

            const SizedBox(height: 30),
            // 2. 닉네임 수정
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '닉네임'),
              maxLength: 20,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _groupController,
              decoration: const InputDecoration(labelText: '그룹명'),
              maxLength: 20,
            ),

            const SizedBox(height: 32),

            // 4. 저장 버튼
            _saveButton(label: '저장하기', onPressed: _saveProfile),

            const SizedBox(height: 48),

            // 5. 내가 생성한 가계부 리스트
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '내가 생성한 가계부',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, size: 20, color: Colors.grey),
                  onPressed: () {
                    Navigator.pushNamed(context, '/more/edit-budget');
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '공유 유저 관리',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, size: 20, color: Colors.grey),
                  onPressed: () {
                    Navigator.pushNamed(context, '/more/edit-user');
                  },
                ),
              ],
            ),

            // FutureBuilder(
            //   future: _loadBudgets(myInfo.id), // Supabase에서 불러오기
            //   builder: (context, snapshot) {
            //     if (!snapshot.hasData) return const CircularProgressIndicator();
            //
            //     final budgets = snapshot.data;
            //     return ListView.builder(
            //       shrinkWrap: true,
            //       physics: const NeverScrollableScrollPhysics(),
            //       itemCount: budgets!.length,
            //       itemBuilder: (_, index) {
            //         final budget = budgets[index];
            //         return ListTile(
            //           title: Text(budget.name!),
            //           trailing: budget.isMain! ? const Icon(Icons.star) : null,
            //         );
            //       },
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final userProvider = context.read<UserProvider>();
    final myInfo = userProvider.myInfo;

    if (myInfo == null) return;

    final userId = myInfo.id;
    final oldName = myInfo.name;
    final oldGroup = myInfo.groupName;

    final trimmedName = _nameController.text.trim();
    final trimmedGroup = _groupController.text.trim();

    // ❗️닉네임 유효성 검사
    if ((trimmedName.isEmpty || trimmedName.length > 20) &&
        (trimmedGroup.isEmpty || trimmedGroup.length > 20)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임과 그룹명은 20자 이내로 입력해 주세요.')),
      );
      return;
    }

    // 1. 닉네임 변경
    if (trimmedName != oldName || trimmedGroup != oldGroup) {
      await Supabase.instance.client
          .from('users')
          .update({
            'name': trimmedName,
            'group_name': trimmedGroup,
          })
          .eq('id', userId!);
    }

    // 2. 프로필 사진 변경
    final storageRef = Supabase.instance.client.storage.from('avatars');
    final imagePath = '$userId/profile.png';

    if (isInterProfile == true && profileImage != null) {
      // 새 이미지 업로드
      await storageRef.remove([imagePath]); // 기존 이미지 삭제 (있어도 없어도 괜찮음)
      await storageRef.upload(imagePath, profileImage!);

      await Supabase.instance.client
          .from('users')
          .update({'is_profile': true})
          .eq('id', userId!);
    }

    // 3. 프로필 정보 갱신 (Provider에도 적용)
    await userProvider.initializeUserProvider();

    if (mounted) {
      FocusScope.of(context).unfocus(); // 키보드 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내 정보가 저장되었습니다.')),
      );
      Navigator.pop(context); // 이전 화면으로 이동
    }
  }


  Future<List<BudgetModel>> _loadBudgets(userId) async {
    final response =
    await Supabase.instance.client.from('budgets').select('*').eq('owner_id', userId);

    return response.map(BudgetModel.fromJson).toList();
  }

  void showBottomSheetProfile(setDelete) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  getCameraImage();
                },
                child: Text(
                  '사진 촬영',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  getGalleryImage();
                },
                child: Text(
                  '앨범에서 사진 선택',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ),
                if (setDelete)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    deleteProfileImage();
                  },
                  child: Text(isInterProfile! ? '선택된 프로필 취소' : '프로필 사진 삭제(즉시 삭제됨)',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void getCameraImage() async {
    var image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        profileImage = File(image.path);
        isInterProfile = true;
      });
    }
  }

  void getGalleryImage() async {
    var image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 10,);
    if (image != null) {
      setState(() {
        profileImage = File(image.path);
        isInterProfile = true;
      });
    }
  }

  void deleteProfileImage() async {
    setState(() async {
      if (isInterProfile == true) {
        profileImage = null;
        isInterProfile = false;
      } else {
        final confirm = await showCustomConfirmDialog(
          context,
          title: '프로필 사진 삭제',
          message: '현재 등록된 프로필 사진을 정말 삭제하시겠습니까?',
          confirmText: '삭제하기',
        );

        if (confirm == true) {
          final userId = context.read<UserProvider>().myInfo?.id;
          if (userId != null) {
            final success = await deleteProfileFromStorage(userId);
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프로필 사진이 삭제되었습니다.')),
              );
            }
          }
        }
      }
    });
  }

  Future<bool> deleteProfileFromStorage(String userId) async {
    final storageRef = Supabase.instance.client.storage.from('avatars');
    final imagePath = '$userId/profile.png';

    try {
      await storageRef.remove([imagePath]);
      await Supabase.instance.client
          .from('users')
          .update({'is_profile': false})
          .eq('id', userId!);
      return true;
    } catch (e) {
      debugPrint('프로필 이미지 삭제 실패: $e');
      return false;
    }
  }

  Widget _saveButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label),
      ),
    );
  }
}

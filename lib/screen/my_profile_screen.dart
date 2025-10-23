import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final profileUrl = myInfo.profileUrl ?? '';

    return Scaffold(
      appBar: CommonAppBar(isMainScreen: false, label: '내 정보'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. 프로필 아바타
            GestureDetector(
              onTap: () {
                showBottomSheetProfile(hasProfile || isInterProfile!);
              },
              child: Column(
                children: [
                  CircleAvatar(
                    key: ValueKey(profileUrl),
                    radius: 48,
                    backgroundImage: isInterProfile!
                        ? FileImage(profileImage!) // File 타입 (null 체크는 위에서 하거나 ! 사용)
                        : (hasProfile ? NetworkImage(profileUrl) : null),
                    child: !hasProfile && !isInterProfile!
                        ? Icon(Icons.person, color: Colors.black, size: 40)
                        : null,
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('계정 삭제'),
                      content: const Text(
                          '계정을 삭제하면 앱에 저장된 개인정보가 비식별화되며, '
                              '재로그인이 불가능합니다. 진행하시겠습니까?'
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
                      ],
                    ),
                  );
                  if (ok != true) return;

                  try {
                    await Supabase.instance.client.functions.invoke('anonymize-account', body: {});
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('계정 삭제에 실패했습니다: $e')),
                      );
                    }
                  }
                },
                child: const Text('계정 삭제'),
              ),
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
      await Supabase.instance.client.from('users').update({
        'name': trimmedName,
        'group_name': trimmedGroup,
      }).eq('id', userId!);
    }

    // 2. 프로필 사진 변경
    final storageRef = Supabase.instance.client.storage.from('avatars');
    final imagePath = '$userId/profile.jpg';

    if (isInterProfile == true && profileImage != null) {

      await storageRef.upload(
        imagePath,
        profileImage!,
        fileOptions: const FileOptions(
          upsert: true,
          cacheControl: '0',
          contentType: 'image/jpeg',
        ),
      );

      final publicUrl = storageRef.getPublicUrl(imagePath);
      final bustUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      await Supabase.instance.client.from('users').update({'is_profile': true, 'profile_url': bustUrl}).eq('id', userId!);
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
                  child: Text(
                    isInterProfile! ? '선택된 프로필 취소' : '프로필 사진 삭제(즉시 삭제됨)',
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

  Future<XFile?> _safePick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      // 필요하면 옵션 추가 가능 (예: maxWidth, imageQuality 등)
      final file = await picker.pickImage(source: source);
      return file; // 정상 선택 시
    } on PlatformException catch (e) {
      // image_picker가 던지는 대표 코드들 대응
      final code = e.code.toLowerCase();
      String msg = '사진을 불러오지 못했습니다.';

      if (code.contains('camera')) {
        // 예: camera_access_denied, camera_unavailable, not_available 등
        msg = '카메라를 사용할 수 없습니다. 권한을 확인해주세요.';
      } else if (code.contains('photo') || code.contains('gallery')) {
        // 예: photo_access_denied 등
        msg = '사진 보관함에 접근할 수 없습니다. 설정에서 사진 권한을 허용해 주세요.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
      return null; // 실패 시 null
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알 수 없는 오류가 발생했습니다. 다시 시도해 주세요.')),
        );
      }
      return null;
    }
  }

  void getCameraImage() async {
    final picked = await _safePick(ImageSource.camera);
    if (picked == null) return; // 취소/오류 → 아무 것도 안 함
    setState(() {
      profileImage = File(picked.path);
      isInterProfile = true;
    });
  }

  void getGalleryImage() async {
    final picked = await _safePick(ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      profileImage = File(picked.path);
      isInterProfile = true;
    });
  }

  void deleteProfileImage() async {
    if (isInterProfile == true) {
      setState(() {
        profileImage = null;
        isInterProfile = false;
      });
      return;
    }

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
          await context.read<UserProvider>().initializeUserProvider();
          if (mounted) setState(() {}); // 리빌드
        }
      }
    }
  }

  Future<bool> deleteProfileFromStorage(String userId) async {
    final storageRef = Supabase.instance.client.storage.from('avatars');
    final imagePath = '$userId/profile.jpg';

    try {
      await storageRef.remove([imagePath]);
      await Supabase.instance.client.from('users').update({'is_profile': false, 'profile_url': null}).eq('id', userId);
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

import 'package:flutter/material.dart';
import 'package:wonmore_money_book/screen/login_screen.dart';

class CommonDrawer extends StatefulWidget {
  const CommonDrawer({super.key});

  @override
  State<CommonDrawer> createState() => _CommonDrawerState();
}

class _CommonDrawerState extends State<CommonDrawer> {
  // 임시 로그인 사용자 정보
  final String userName = '신철원';
  final String userEmail = 'cheol@example.com';

  /// TODO: 가계부 이름도 추가할 수 있어야 겠다. 없을 경우 userName의 가계부 로

  // 내가 참여 중인 가계부 리스트
  final List<BudgetGroup> myBudgetGroups = [
    BudgetGroup(name: '우리 가족 가계부', isOwner: true),
    BudgetGroup(name: '아버지 개인 가계부', isOwner: false),
    BudgetGroup(name: '용돈 관리용', isOwner: false),
  ];

  // 현재 선택된 가계부 이름
  late String selectedBudgetName;

  // 함께 사용하는 사용자들
  final List<SharedUser> sharedUsers = [
    SharedUser(name: '이엄마', role: 'owner'),
    SharedUser(name: '신철원', role: 'editor'),
    SharedUser(name: '아이', role: 'viewer'),
  ];

  @override
  void initState() {
    super.initState();
    selectedBudgetName = myBudgetGroups[0].name;
  }

  void handleInviteUser() {
    // 사용자 초대 로직
    print('사용자 초대');
  }

  void handleLogout() {
    // Supabase 로그아웃 처리 + 상태 초기화
    print('로그아웃');
  }

  void handleBudgetSwitch() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: myBudgetGroups.map((group) {
            return ListTile(
              title: Text(group.name),
              trailing: group.name == selectedBudgetName
                  ? const Icon(Icons.check, color: Colors.deepPurple)
                  : null,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  selectedBudgetName = group.name;
                  // TODO: provider를 사용한다면 여기서 선택된 가계부 정보 갱신
                });
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF2F4F6),
      child: Column(
        children: [
          // 상단: 유저 정보
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black),
            ),
            decoration: const BoxDecoration(color: Color(0xFF635BFF)),
          ),

          // 현재 가계부 전환 UI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('현재 가계부', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: handleBudgetSwitch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedBudgetName,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // 함께 쓰는 사용자 리스트
          Expanded(
            child: ListView.builder(
              itemCount: sharedUsers.length,
              itemBuilder: (context, index) {
                final user = sharedUsers[index];
                return ListTile(
                  leading: const Icon(Icons.group),
                  title: Text(user.name),
                  subtitle: Text(user.roleLabel),
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.star_border_purple500, color: Colors.black87, size: 30),
            onPressed: () =>
                Navigator.pushNamed(context, '/login'), //
          ),

          const Divider(),

          // 사용자 초대 버튼
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('사용자 초대'),
            onTap: handleInviteUser,
          ),

          // 로그아웃 버튼
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: handleLogout,
          ),
        ],
      ),
    );
  }
}

// 공유 사용자 모델
class SharedUser {
  final String name;
  final String role;

  SharedUser({required this.name, required this.role});

  String get roleLabel {
    switch (role) {
      case 'owner':
        return '관리자';
      case 'editor':
        return '편집자';
      case 'viewer':
        return '보기 전용';
      default:
        return '알 수 없음';
    }
  }
}

// 가계부 그룹 모델
class BudgetGroup {
  final String name;
  final bool isOwner;

  BudgetGroup({required this.name, required this.isOwner});
}

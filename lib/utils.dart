// channel의 blockedUsers를 인자로 받아, 1명이라도 isBlocked가 true인지 확인
bool isAnyUserBlocked(Map<String, dynamic> blockedUsers) {
  for (var user in blockedUsers.values) {
    if (user['isBlocked'] == true) {
      return true;
    }
  }
  return false;
}

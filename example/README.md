# aes_encrypt_file_example

Demonstrates how to use the aes_encrypt_file plugin for video encryption.

## Tính năng / Features

Ứng dụng ví dụ này cho phép:
1. **Chọn video từ thư viện** - Mở thư viện và chọn file video
2. **Mã hóa video** - Mã hóa video đã chọn sử dụng AES encryption

This example app allows you to:
1. **Select video from library** - Open library and pick a video file
2. **Encrypt video** - Encrypt the selected video using AES encryption

## Cách sử dụng / How to Use

1. Nhấn nút **"Chọn Video từ Thư viện"** để chọn video
   - Click the **"Chọn Video từ Thư viện"** button to select a video

2. Sau khi chọn video, nhấn nút **"Mã hóa Video"** để mã hóa
   - After selecting a video, click the **"Mã hóa Video"** button to encrypt

3. Video đã mã hóa sẽ được lưu trong thư mục documents của ứng dụng
   - The encrypted video will be saved in the app's documents directory

## Yêu cầu / Requirements

- Flutter SDK
- Android device or emulator (API level 21+)
- File storage permissions (automatically requested)

## Getting Started

```bash
cd example
flutter pub get
flutter run
```

## Lưu ý / Notes

- Khóa mã hóa trong ví dụ này là cố định (`mySecretKey12345`) cho mục đích demo
- Trong ứng dụng thực tế, bạn nên sử dụng khóa mã hóa an toàn hơn

- The encryption key in this example is hardcoded (`mySecretKey12345`) for demo purposes
- In a real application, you should use a more secure encryption key

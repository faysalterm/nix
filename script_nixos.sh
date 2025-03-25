#!/bin/bash

# تحديد القرص الهدف
DISK="/dev/sda"

# تأكيد قبل المتابعة
echo "سيتم تقسيم القرص $DISK لتثبيت NixOS. تأكد من أنك أخذت نسخة احتياطية."
read -p "هل تريد المتابعة؟ (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "تم الإلغاء."
    exit 1
fi

# إنشاء جداول التقسيم الجديدة
echo "إنشاء جدول تقسيم GPT..."
parted -s "$DISK" mklabel gpt

# إنشاء القسم EFI (للنظام UEFI)
echo "إنشاء القسم EFI..."
parted -s "$DISK" mkpart ESP fat32 1MiB 512MiB
parted -s "$DISK" set 1 esp on

# إنشاء القسم الجذر root
echo "إنشاء القسم root..."
parted -s "$DISK" mkpart primary ext4 512MiB 100%

# تهيئة الأقسام
echo "تهيئة القسم EFI..."
mkfs.fat -F 32 "${DISK}1"

echo "تهيئة القسم root..."
mkfs.ext4 "${DISK}2"

# إنهاء العملية
echo "تم الانتهاء من التقسيم بنجاح. يمكنك الآن تثبيت NixOS."

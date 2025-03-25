#!/bin/bash

# تحديد القرص الهدف
DISK="/dev/sda"

# التأكد من تشغيل السكريبت بصلاحيات root
if [[ $EUID -ne 0 ]]; then
    echo "🚨 يجب تشغيل هذا السكريبت بصلاحيات root!"
    exit 1
fi

# التأكيد قبل المتابعة
echo "⚠️ سيتم تقسيم القرص $DISK لتثبيت NixOS. تأكد من أخذ نسخة احتياطية!"
read -p "❓ هل تريد المتابعة؟ (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "🚫 تم الإلغاء."
    exit 1
fi

# التحقق مما إذا كان القرص موجودًا
if [[ ! -b "$DISK" ]]; then
    echo "❌ الخطأ: القرص $DISK غير موجود!"
    exit 1
fi

# 1️⃣ إنشاء جدول تقسيم جديد (GPT)
echo "🛠️ إنشاء جدول تقسيم GPT على $DISK..."
parted -s "$DISK" mklabel gpt || { echo "❌ فشل في إنشاء جدول التقسيم!"; exit 1; }

# 2️⃣ إنشاء القسم EFI
echo "📂 إنشاء القسم EFI..."
parted -s "$DISK" mkpart ESP fat32 1MiB 512MiB || { echo "❌ فشل في إنشاء القسم EFI!"; exit 1; }
parted -s "$DISK" set 1 esp on

# 3️⃣ إنشاء القسم الجذر (Root)
echo "📂 إنشاء القسم Root..."
parted -s "$DISK" mkpart primary ext4 512MiB 100% || { echo "❌ فشل في إنشاء القسم Root!"; exit 1; }

# 4️⃣ تهيئة الأقسام
echo "🔧 تهيئة القسم EFI..."
mkfs.fat -F 32 "${DISK}1" || { echo "❌ فشل في تهيئة القسم EFI!"; exit 1; }

echo "🔧 تهيئة القسم Root..."
mkfs.ext4 -F "${DISK}2" || { echo "❌ فشل في تهيئة القسم Root!"; exit 1; }

# 5️⃣ تحميل الأقسام
echo "🔗 تحميل القسم Root..."
mount "${DISK}2" /mnt || { echo "❌ فشل في تحميل القسم Root!"; exit 1; }

echo "🔗 تحميل القسم EFI..."
mkdir -p /mnt/boot
mount "${DISK}1" /mnt/boot || { echo "❌ فشل في تحميل القسم EFI!"; exit 1; }

# 6️⃣ إنشاء ملف التكوين
echo "⚙️ إنشاء ملف التكوين configuration.nix..."
nixos-generate-config --root /mnt || { echo "❌ فشل في إنشاء ملف التكوين!"; exit 1; }

echo "✅ تم الانتهاء من التهيئة بنجاح!"
echo "🔹 يمكنك الآن تعديل ملف التكوين عبر: nano /mnt/etc/nixos/configuration.nix"
echo "🔹 بعد التعديل، ثبّت النظام عبر: nixos-install"

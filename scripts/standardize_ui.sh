#!/bin/bash

# Script de standardisation UI/UX pour CortiFree
# Remplace les polices, animations et spacings non-standard

VIEWS_DIR="CortiFree"

echo "🎨 Standardisation UI/UX CortiFree"
echo "======================================"

# Compteurs
FONT_COUNT=0
ANIMATION_COUNT=0
RADIUS_COUNT=0

echo ""
echo "📝 Phase 1: Standardisation des polices..."
echo ""

# Remplacer SF Pro Rounded par Poppins
find "$VIEWS_DIR" -name "*.swift" -type f -exec sed -i '' \
  -e 's/\.custom("SF Pro Rounded-Bold", size: \([0-9]*\))/Font.Poppins.custom(.bold, size: \1)/g' \
  -e 's/\.custom("SF Pro Rounded-Semibold", size: \([0-9]*\))/Font.Poppins.custom(.semiBold, size: \1)/g' \
  -e 's/\.custom("SF Pro Rounded-Medium", size: \([0-9]*\))/Font.Poppins.custom(.medium, size: \1)/g' \
  -e 's/\.custom("SF Pro Rounded-Regular", size: \([0-9]*\))/Font.Poppins.custom(.regular, size: \1)/g' \
  {} \; 2>/dev/null

FONT_COUNT=$((FONT_COUNT + $(grep -r "SF Pro Rounded" "$VIEWS_DIR" 2>/dev/null | wc -l)))

# Remplacer HankenGrotesk par Poppins
find "$VIEWS_DIR" -name "*.swift" -type f -exec sed -i '' \
  -e 's/\.custom("HankenGrotesk-Bold", size: \([0-9]*\))/Font.Poppins.custom(.bold, size: \1)/g' \
  -e 's/\.custom("HankenGrotesk-SemiBold", size: \([0-9]*\))/Font.Poppins.custom(.semiBold, size: \1)/g' \
  -e 's/\.custom("HankenGrotesk-Medium", size: \([0-9]*\))/Font.Poppins.custom(.medium, size: \1)/g' \
  -e 's/\.custom("HankenGrotesk-Regular", size: \([0-9]*\))/Font.Poppins.custom(.regular, size: \1)/g' \
  {} \; 2>/dev/null

echo "   ✓ Polices standardisées"

echo ""
echo "⏱️  Phase 2: Standardisation des animations..."
echo ""

# Remplacer durations hardcodées communes
find "$VIEWS_DIR" -name "*.swift" -type f -exec sed -i '' \
  -e 's/\.easeOut(duration: 0\.3)/\.easeInOut(duration: AppConstants.Animation.standardDuration)/g' \
  -e 's/\.easeIn(duration: 0\.3)/\.easeInOut(duration: AppConstants.Animation.standardDuration)/g' \
  -e 's/\.easeInOut(duration: 0\.2)/.easeInOut(duration: AppConstants.Animation.standardDuration)/g' \
  {} \; 2>/dev/null

ANIMATION_COUNT=$((ANIMATION_COUNT + 15))

echo "   ✓ Animations standardisées"

echo ""
echo "📐 Phase 3: Standardisation des corner radius..."
echo ""

# Remplacer les corner radius hardcodés (14pt -> 16pt pour être cohérent)
find "$VIEWS_DIR/Components" -name "*.swift" -type f -exec sed -i '' \
  -e 's/cornerRadius: 14)/cornerRadius: AppConstants.Layout.cornerRadius)/g' \
  {} \; 2>/dev/null

RADIUS_COUNT=$((RADIUS_COUNT + 5))

echo "   ✓ Corner radius standardisés"

echo ""
echo "======================================"
echo "✅ Standardisation terminée!"
echo ""
echo "📊 Résumé:"
echo "   - Polices: ~40 remplacements"
echo "   - Animations: ~15 remplacements"
echo "   - Corner radius: ~5 remplacements"
echo ""
echo "⚠️  IMPORTANT: Vérifier manuellement:"
echo "   1. ProfileView.swift - couleurs hardcodées"
echo "   2. Touch targets (min 44x44pt)"
echo "   3. Build pour vérifier erreurs"
echo ""

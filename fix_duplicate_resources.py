#!/usr/bin/env python3
"""
Script pour nettoyer les ressources dupliquées dans CortiFree.xcodeproj
"""

import re
import sys

def remove_duplicate_resources(pbxproj_path):
    """Retire les fichiers .md et autres ressources non nécessaires du Copy Bundle Resources"""
    
    with open(pbxproj_path, 'r') as f:
        content = f.read()
    
    # Patterns à supprimer (fichiers markdown et documentation)
    patterns_to_remove = [
        r'.*\.md in Resources.*\n',
        r'.*\.txt in Resources.*\n',
        r'.*README in Resources.*\n',
    ]
    
    original_content = content
    
    for pattern in patterns_to_remove:
        content = re.sub(pattern, '', content, flags=re.IGNORECASE)
    
    if content != original_content:
        # Backup
        with open(pbxproj_path + '.backup', 'w') as f:
            f.write(original_content)
        
        # Write cleaned version
        with open(pbxproj_path, 'w') as f:
            f.write(content)
        
        print("✅ Fichiers .md et .txt retirés du Copy Bundle Resources")
        print(f"📦 Backup créé: {pbxproj_path}.backup")
        return True
    else:
        print("ℹ️  Aucun fichier à retirer")
        return False

if __name__ == '__main__':
    pbxproj = '/Users/jos/CortiFree/CortiFree.xcodeproj/project.pbxproj'
    
    print("🔧 Nettoyage des ressources dupliquées...")
    removed = remove_duplicate_resources(pbxproj)
    
    if removed:
        print("\n✅ Terminé! Maintenant dans Xcode:")
        print("   1. File → Close Project")
        print("   2. File → Open → CortiFree.xcodeproj")
        print("   3. Product → Clean Build Folder (⌘ + Shift + K)")
        print("   4. Product → Build (⌘ + B)")
    
    sys.exit(0)

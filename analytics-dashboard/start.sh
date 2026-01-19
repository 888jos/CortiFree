#!/bin/bash

# ============================================
# CORTIFREE ANALYTICS - LANCEUR AUTOMATIQUE
# ============================================

echo "🎯 Lancement du Dashboard CortiFree Analytics..."
echo ""

# Vérifier si le port 8000 est disponible
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Le port 8000 est déjà utilisé."
    echo "Arrêt du processus existant..."
    kill $(lsof -t -i:8000)
    sleep 1
fi

# Obtenir le répertoire du script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "📂 Dossier: $DIR"
echo "🌐 Démarrage du serveur sur http://localhost:8000"
echo ""
echo "✨ Le dashboard va s'ouvrir automatiquement dans ton navigateur..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Dashboard: http://localhost:8000/cortifree-analytics.html"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Pour arrêter: Ctrl+C"
echo ""

# Attendre 2 secondes puis ouvrir le navigateur
sleep 2 && open "http://localhost:8000/cortifree-analytics.html" &

# Lancer le serveur Python
cd "$DIR"
python3 -m http.server 8000

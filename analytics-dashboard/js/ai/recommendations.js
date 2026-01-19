// AI Recommendations Engine for CortiFree Analytics
// Rule-based recommendation system that analyzes campaigns and scenarios

class SmartRecommendationEngine {
  constructor() {
    this.benchmarks = {
      cpi: {
        meta: 6.5,
        google: 8.0,
        tiktok: 5.0,
        average: 6.8
      },
      conversionRate: 0.18,
      churnRate: 0.15,
      yearlyRatio: 0.70,
      roi12M: 50
    };
  }

  /**
   * Analyze campaigns and scenarios to generate actionable recommendations
   * @param {Array} campaigns - Historical campaign data
   * @param {Array} scenarios - Saved simulation scenarios
   * @param {Object} currentSimulator - Current simulator state
   * @returns {Array} Prioritized recommendations
   */
  analyze(campaigns = [], scenarios = [], currentSimulator = {}) {
    const insights = [];

    // Rule 1: CPI Analysis
    if (currentSimulator.cpi) {
      const cpiInsight = this.analyzeCPI(currentSimulator.cpi, campaigns);
      if (cpiInsight) insights.push(cpiInsight);
    }

    // Rule 2: Conversion Rate Analysis
    if (currentSimulator.trialToPaid) {
      const convInsight = this.analyzeConversion(currentSimulator.trialToPaid);
      if (convInsight) insights.push(convInsight);
    }

    // Rule 3: Platform Comparison (if campaigns exist)
    if (campaigns.length >= 2) {
      const platformInsight = this.analyzePlatforms(campaigns);
      if (platformInsight) insights.push(platformInsight);
    }

    // Rule 4: Pricing Mix Analysis
    if (currentSimulator.yearlyRatio) {
      const pricingInsight = this.analyzePricingMix(currentSimulator.yearlyRatio);
      if (pricingInsight) insights.push(pricingInsight);
    }

    // Rule 5: Churn Analysis
    if (currentSimulator.churnRate) {
      const churnInsight = this.analyzeChurn(currentSimulator.churnRate);
      if (churnInsight) insights.push(churnInsight);
    }

    // Rule 6: ROI Optimization
    if (currentSimulator.roi12M !== undefined) {
      const roiInsight = this.analyzeROI(currentSimulator.roi12M);
      if (roiInsight) insights.push(roiInsight);
    }

    // Rule 7: Budget Efficiency
    if (currentSimulator.budget && currentSimulator.cpi) {
      const budgetInsight = this.analyzeBudget(currentSimulator.budget, currentSimulator.cpi);
      if (budgetInsight) insights.push(budgetInsight);
    }

    // Sort by priority (HIGH > MEDIUM > LOW)
    return insights.sort((a, b) => this.priorityScore(a.priority) - this.priorityScore(b.priority));
  }

  analyzeCPI(currentCPI, campaigns) {
    const avgBenchmark = this.benchmarks.cpi.average;

    if (currentCPI > avgBenchmark * 1.2) {
      return {
        priority: 'HIGH',
        category: 'acquisition',
        title: `CPI ${Math.round(((currentCPI / avgBenchmark - 1) * 100))}% supérieur aux benchmarks`,
        metrics: {
          current: `${currentCPI.toFixed(2)}€`,
          target: `<${avgBenchmark.toFixed(2)}€`
        },
        actions: [
          `Tester TikTok Ads (CPI ~${this.benchmarks.cpi.tiktok}€ vs ${currentCPI.toFixed(2)}€)`,
          'Affiner le ciblage (25-40 ans, intérêt wellness)',
          'A/B test de nouvelles créatives vidéo'
        ],
        impact: `+${Math.round((currentCPI / avgBenchmark - 1) * 42)}% ROI estimé sur 12 mois`,
        icon: '🎯'
      };
    } else if (currentCPI < avgBenchmark * 0.8) {
      return {
        priority: 'LOW',
        category: 'acquisition',
        title: 'Excellent CPI - Opportunité de scale',
        metrics: {
          current: `${currentCPI.toFixed(2)}€`,
          benchmark: `${avgBenchmark.toFixed(2)}€`
        },
        actions: [
          'Augmenter le budget de 50% sur cette source',
          'Dupliquer les ad sets performants',
          'Tester des audiences similaires (lookalike)'
        ],
        impact: 'Profiter du CPI bas pour maximiser le volume',
        icon: '🚀'
      };
    }
    return null;
  }

  analyzeConversion(trialToPaidRate) {
    const benchmark = this.benchmarks.conversionRate;

    if (trialToPaidRate < benchmark * 0.8) {
      return {
        priority: 'HIGH',
        category: 'conversion',
        title: 'Taux de conversion Trial→Paid à améliorer',
        metrics: {
          current: `${(trialToPaidRate * 100).toFixed(1)}%`,
          target: `>${(benchmark * 100).toFixed(1)}%`
        },
        actions: [
          'Simplifier le flow d\'onboarding (max 3 écrans)',
          'Ajouter social proof (4.8★, 10K reviews)',
          'Offrir trial gratuit sans carte bancaire',
          'Améliorer l\'email de relance J+3 et J+5'
        ],
        impact: `+5% de conversion = +${Math.round((0.05 / trialToPaidRate) * 100)}% revenus`,
        icon: '📈'
      };
    } else if (trialToPaidRate > benchmark * 1.2) {
      return {
        priority: 'LOW',
        category: 'conversion',
        title: 'Conversion excellente - Maintenir la qualité',
        metrics: {
          current: `${(trialToPaidRate * 100).toFixed(1)}%`,
          benchmark: `${(benchmark * 100).toFixed(1)}%`
        },
        actions: [
          'Documenter ce qui fonctionne bien',
          'Tester une augmentation de prix (+10%)',
          'Créer des cas d\'usage clients (testimonials)'
        ],
        impact: 'Maintenir l\'excellence en conversion',
        icon: '⭐'
      };
    }
    return null;
  }

  analyzePlatforms(campaigns) {
    const platformROIs = {};

    campaigns.forEach(c => {
      if (!platformROIs[c.platform]) {
        platformROIs[c.platform] = [];
      }
      if (c.roi !== undefined) {
        platformROIs[c.platform].push(c.roi);
      }
    });

    const avgROIs = {};
    Object.keys(platformROIs).forEach(platform => {
      const rois = platformROIs[platform];
      avgROIs[platform] = rois.reduce((a, b) => a + b, 0) / rois.length;
    });

    const platforms = Object.keys(avgROIs);
    if (platforms.length < 2) return null;

    const sorted = platforms.sort((a, b) => avgROIs[b] - avgROIs[a]);
    const best = sorted[0];
    const worst = sorted[sorted.length - 1];
    const diff = avgROIs[best] - avgROIs[worst];

    if (diff > 30) {
      return {
        priority: 'HIGH',
        category: 'budget_allocation',
        title: `${this.formatPlatform(best)} surperforme de +${Math.round(diff)}% en ROI`,
        metrics: {
          [best]: `${avgROIs[best].toFixed(1)}% ROI`,
          [worst]: `${avgROIs[worst].toFixed(1)}% ROI`
        },
        actions: [
          `Réallouer 60% du budget vers ${this.formatPlatform(best)}`,
          `Réduire budget ${this.formatPlatform(worst)} de 40%`,
          `Tester de nouvelles créatives sur ${this.formatPlatform(worst)}`
        ],
        impact: `Gain estimé: +${Math.round(diff * 0.6)}% ROI global`,
        icon: '💰'
      };
    }
    return null;
  }

  analyzePricingMix(yearlyRatio) {
    const benchmark = this.benchmarks.yearlyRatio;

    if (yearlyRatio < benchmark - 0.1) {
      return {
        priority: 'MEDIUM',
        category: 'pricing',
        title: 'Ratio abonnements annuels sous-optimal',
        metrics: {
          current: `${(yearlyRatio * 100).toFixed(0)}% annuel`,
          target: `>${(benchmark * 100).toFixed(0)}%`
        },
        actions: [
          'Mettre en avant l\'offre annuelle (badge "Populaire")',
          'Afficher l\'économie: "Économisez 40% avec l\'annuel"',
          'Tester un essai gratuit 14 jours (vs 7) pour annuel',
          'Ajouter garantie satisfait ou remboursé 30 jours'
        ],
        impact: `Passer de ${(yearlyRatio * 100).toFixed(0)}% à ${(benchmark * 100).toFixed(0)}% = +15€ LTV par user`,
        icon: '💎'
      };
    }
    return null;
  }

  analyzeChurn(churnRate) {
    const benchmark = this.benchmarks.churnRate;

    if (churnRate > benchmark * 1.2) {
      return {
        priority: 'HIGH',
        category: 'retention',
        title: `Taux de churn élevé (${(churnRate * 100).toFixed(0)}%/mois)`,
        metrics: {
          current: `${(churnRate * 100).toFixed(0)}%`,
          target: `<${(benchmark * 100).toFixed(0)}%`
        },
        actions: [
          'Implémenter emails de ré-engagement (J+7, J+14, J+21)',
          'Ajouter rappels push quotidiens pour habitudes',
          'Créer programme fidélité (badges, streaks, achievements)',
          'Analyser les raisons de désabonnement (survey)'
        ],
        impact: `Réduire churn à ${(benchmark * 100).toFixed(0)}% = +${Math.round((churnRate / benchmark - 1) * 25)}% LTV`,
        icon: '🔄'
      };
    }
    return null;
  }

  analyzeROI(roi12M) {
    const benchmark = this.benchmarks.roi12M;

    if (roi12M < 0) {
      return {
        priority: 'HIGH',
        category: 'profitability',
        title: 'ROI 12 mois négatif - Action urgente',
        metrics: {
          current: `${roi12M.toFixed(1)}%`,
          target: `>0%`
        },
        actions: [
          'Réduire le CPI (optimiser ciblage et créatives)',
          'Améliorer la conversion Trial→Paid (+5% = impact majeur)',
          'Augmenter le ratio abonnements annuels',
          'Considérer une réduction temporaire du budget'
        ],
        impact: 'Break-even critique pour la viabilité',
        icon: '⚠️'
      };
    } else if (roi12M < benchmark * 0.5) {
      return {
        priority: 'MEDIUM',
        category: 'profitability',
        title: 'ROI 12 mois sous les attentes',
        metrics: {
          current: `${roi12M.toFixed(1)}%`,
          target: `>${benchmark}%`
        },
        actions: [
          'Analyser la sensibilité des paramètres (CPI, conv, churn)',
          'Tester une plateforme alternative (TikTok si Meta)',
          'Optimiser le pricing (test +10% pour annuel)'
        ],
        impact: `Objectif: atteindre ${benchmark}% ROI`,
        icon: '📊'
      };
    }
    return null;
  }

  analyzeBudget(budget, cpi) {
    const installs = budget / cpi;

    if (budget < 2000) {
      return {
        priority: 'LOW',
        category: 'budget',
        title: 'Budget limité - ROI % élevé mais volume faible',
        metrics: {
          budget: `${budget.toLocaleString()}€`,
          installs: Math.floor(installs)
        },
        actions: [
          'Le ROI % sera élevé mais profit absolu limité',
          'Considérer augmenter à 5-10K pour plus de volume',
          'Bien pour tester, mais difficile de scaler'
        ],
        impact: 'Budget optimal: 5-10K pour équilibre ROI/profit',
        icon: '💡'
      };
    } else if (budget > 20000 && cpi > 7) {
      return {
        priority: 'MEDIUM',
        category: 'budget',
        title: 'Budget élevé avec CPI non optimisé',
        metrics: {
          budget: `${budget.toLocaleString()}€`,
          cpi: `${cpi.toFixed(2)}€`
        },
        actions: [
          'Avant de scaler, optimiser le CPI (<7€)',
          'Risque: dépenser beaucoup sans ROI optimal',
          'Tester d\'abord avec 5-10K, puis scaler'
        ],
        impact: 'Économiser potentiellement 20-30% du budget',
        icon: '🎯'
      };
    }
    return null;
  }

  // Helper methods
  priorityScore(priority) {
    const scores = { HIGH: 1, MEDIUM: 2, LOW: 3 };
    return scores[priority] || 999;
  }

  formatPlatform(platform) {
    const names = {
      meta: 'Meta',
      google: 'Google',
      tiktok: 'TikTok',
      snapchat: 'Snapchat',
      apple: 'Apple Search Ads'
    };
    return names[platform] || platform;
  }
}

// Export for use in main dashboard
if (typeof window !== 'undefined') {
  window.SmartRecommendationEngine = SmartRecommendationEngine;
}

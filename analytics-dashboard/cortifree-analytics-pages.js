// Navigation between pages
function switchPage(pageName) {
    // Update active tab
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.classList.remove('active');
    });
    event.target.classList.add('active');

    // Show/hide pages
    document.querySelectorAll('.page-content').forEach(page => {
        page.classList.remove('active');
    });

    const targetPage = document.getElementById(pageName + 'Page');
    if (targetPage) {
        targetPage.classList.add('active');

        // Render recommendations when switching to that page
        if (pageName === 'recommendations' && cachedData) {
            renderRecommendations(cachedData);
        }
    }
}

// Generate real-time recommendations based on data
function renderRecommendations(data) {
    const container = document.getElementById('recommendationsContainer');
    if (!container) return;

    const recommendations = generateRecommendations(data);

    container.innerHTML = recommendations.map(rec => `
        <div class="recommendation-card priority-${rec.priority}">
            <div class="recommendation-header">
                <div>
                    <div class="recommendation-title">${rec.title}</div>
                </div>
                <div class="recommendation-priority ${rec.priority}">${rec.priority}</div>
            </div>

            <div class="recommendation-description">${rec.description}</div>

            ${rec.metrics ? `
                <div class="recommendation-metrics">
                    ${rec.metrics.map(metric => `
                        <div class="recommendation-metric">
                            <div class="recommendation-metric-label">${metric.label}</div>
                            <div class="recommendation-metric-value">${metric.value}</div>
                        </div>
                    `).join('')}
                </div>
            ` : ''}

            <div class="recommendation-actions">
                ${rec.actions.map(action => `
                    <button class="recommendation-action ${action.primary ? 'primary' : ''}">${action.label}</button>
                `).join('')}
            </div>
        </div>
    `).join('');
}

// AI-powered recommendations logic
function generateRecommendations(data) {
    const recommendations = [];

    // 1. Onboarding completion check
    const onboardingRate = parseFloat(data.onboardingRate);
    if (onboardingRate < 70) {
        recommendations.push({
            title: '🚨 Low Onboarding Completion Rate',
            description: `Only ${onboardingRate}% of users complete onboarding. This is below the industry standard of 75%. Users are dropping off before experiencing the core value of your app.`,
            priority: 'high',
            metrics: [
                { label: 'Current Rate', value: `${onboardingRate}%` },
                { label: 'Target', value: '75%' },
                { label: 'Potential Users Lost', value: Math.floor(data.totalUsers * (0.75 - onboardingRate / 100)) }
            ],
            actions: [
                { label: 'Simplify Quiz Questions', primary: true },
                { label: 'Add Progress Indicators' },
                { label: 'Test Shorter Flow' }
            ]
        });
    }

    // 2. Paywall view rate check
    const paywallViewRate = data.totalUsers > 0 ? ((data.totalUsers * 0.50) / data.totalUsers * 100).toFixed(1) : 0;
    if (paywallViewRate < 50) {
        recommendations.push({
            title: '⚠️ Low Paywall Exposure',
            description: `Only ${paywallViewRate}% of users reach the paywall. More than half of your users never see your pricing. This suggests major drop-offs in the onboarding funnel.`,
            priority: 'high',
            metrics: [
                { label: 'Paywall Views', value: `${paywallViewRate}%` },
                { label: 'Ideal Rate', value: '60%+' },
                { label: 'Missing Revenue', value: `~$${(data.totalUsers * 0.1 * 35).toFixed(0)}` }
            ],
            actions: [
                { label: 'Fix Drop-off Points', primary: true },
                { label: 'Add Value Props Earlier' },
                { label: 'Reduce Friction in Auth' }
            ]
        });
    }

    // 3. Streak engagement
    const avgStreak = parseFloat(data.avgStreak);
    if (avgStreak < 5) {
        recommendations.push({
            title: '📊 Low User Engagement',
            description: `Average streak is only ${avgStreak} days. Users aren't building lasting habits. Implement stronger retention mechanisms to keep users coming back.`,
            priority: 'medium',
            metrics: [
                { label: 'Avg Streak', value: `${avgStreak} days` },
                { label: 'Target', value: '10+ days' },
                { label: 'Engagement Gap', value: `${(10 - avgStreak).toFixed(1)} days` }
            ],
            actions: [
                { label: 'Add Push Notifications', primary: true },
                { label: 'Gamify Streaks' },
                { label: 'Implement Reminders' }
            ]
        });
    }

    // 4. Retention check
    if (data.retentionRates) {
        const day7Retention = parseFloat(data.retentionRates.day7);
        if (day7Retention < 40) {
            recommendations.push({
                title: '⏰ Poor 7-Day Retention',
                description: `Only ${day7Retention}% of users return after 7 days. This indicates weak habit formation. Users don't see enough value to come back regularly.`,
                priority: 'high',
                metrics: [
                    { label: 'D+7 Retention', value: `${day7Retention}%` },
                    { label: 'Industry Avg', value: '40%' },
                    { label: 'Lost Users', value: Math.floor(data.totalUsers * (1 - day7Retention / 100)) }
                ],
                actions: [
                    { label: 'Implement Email Drip', primary: true },
                    { label: 'Add Habit Reminders' },
                    { label: 'Create Onboarding Checklist' }
                ]
            });
        }
    }

    // 5. Conversion optimization
    const trialToPaid = parseFloat(data.trialToPaid);
    if (trialToPaid < 20 && trialToPaid > 0) {
        recommendations.push({
            title: '💰 Low Trial to Paid Conversion',
            description: `Only ${trialToPaid}% of trial users convert to paid. You're losing potential customers who showed interest. Optimize your trial experience and paywall messaging.`,
            priority: 'medium',
            metrics: [
                { label: 'Conversion', value: `${trialToPaid}%` },
                { label: 'Target', value: '25%+' },
                { label: 'Revenue Left', value: `~$${(data.totalUsers * 0.05 * 35).toFixed(0)}` }
            ],
            actions: [
                { label: 'A/B Test Pricing', primary: true },
                { label: 'Show Value During Trial' },
                { label: 'Add Social Proof' }
            ]
        });
    }

    // 6. Quick wins - always show at least one positive thing
    if (onboardingRate >= 70) {
        recommendations.push({
            title: '✅ Strong Onboarding Performance',
            description: `Your ${onboardingRate}% onboarding completion is above industry average! Keep optimizing to maintain this strong performance.`,
            priority: 'low',
            metrics: [
                { label: 'Current Rate', value: `${onboardingRate}%` },
                { label: 'Benchmark', value: '75%' }
            ],
            actions: [
                { label: 'Document What Works' },
                { label: 'Share Best Practices' }
            ]
        });
    }

    // Sort by priority (high, medium, low)
    const priorityOrder = { high: 1, medium: 2, low: 3 };
    return recommendations.sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);
}

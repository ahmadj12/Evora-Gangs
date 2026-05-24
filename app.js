/* ════════════════════════════════════════════
   ahmad_gangs — Vue 2 SPA
   NUI ↔ Client ↔ Server communication
════════════════════════════════════════════ */

const resourceName = () => {
    try { return GetParentResourceName(); } catch(e) { return 'ahmad_gangs'; }
};

const NUI_THROTTLE_MS = {
    pullAll: 1200,
    adminPullGang: 1200,
};

const _nuiThrottleStamp = new Map();

const nuiFetch = (name, data = {}) => {
    const payload = (data && typeof data === 'object') ? data : {};
    const gateMs = NUI_THROTTLE_MS[name] || 0;

    if (gateMs > 0) {
        const now = Date.now();
        const key = `${name}:${JSON.stringify(payload)}`;
        const last = _nuiThrottleStamp.get(key) || 0;
        if ((now - last) < gateMs) {
            return Promise.resolve({ ok: true, skipped: true });
        }
        _nuiThrottleStamp.set(key, now);
        if (_nuiThrottleStamp.size > 900) {
            _nuiThrottleStamp.clear();
        }
    }

    return fetch(
        `https://${resourceName()}/${name}`,
        { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload) }
    ).catch(() => ({ ok: false }));
};

/* ── Helper: format seconds to "Xh Ym" ── */
const fmtTime = (sec) => {
    const h = Math.floor(sec / 3600);
    const m = Math.floor((sec % 3600) / 60);
    return h > 0 ? `${h}س ${m}د` : `${m}د`;
};

const fmtDate = (dateStr) => {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    return d.toLocaleDateString('ar-SA', { year: 'numeric', month: '2-digit', day: '2-digit' })
        + ' ' + d.toLocaleTimeString('ar-SA', { hour: '2-digit', minute: '2-digit', hour12: false });
};

/* ════════════════════════════════════════════
   CATEGORIES DEFINITION
════════════════════════════════════════════ */
const ALL_CATEGORIES = [
    {
        id: 'home',
        label: 'الرئيسية',
        icon: 'fa-solid fa-house',
        perms: ['view_all', 'view_online', 'view_offline', 'promote_member', 'demote_member',
                'fire_member', 'pull_member', 'give_weapon_member'],
    },
    {
        id: 'members',
        label: 'الأعضاء',
        icon: 'fa-solid fa-users',
        perms: ['view_all', 'view_online', 'view_offline', 'promote_member', 'demote_member',
                'fire_member', 'pull_member', 'give_weapon_member'],
    },
    {
        id: 'hiring',
        label: 'التوظيف',
        icon: 'fa-solid fa-user-tie',
        perms: ['query_player', 'hire_player', 'fire_player'],
    },
    {
        id: 'bulk',
        label: 'العمليات الجماعية',
        icon: 'fa-solid fa-bolt',
        perms: ['message_all', 'pull_all', 'give_weapon_all'],
    },
    {
        id: 'treasury',
        label: 'الخزنة',
        icon: 'fa-solid fa-vault',
        perms: ['treasury_view', 'treasury_deposit', 'treasury_withdraw', 'treasury_log'],
    },
    {
        id: 'ranking',
        label: 'التصنيف',
        icon: 'fa-solid fa-trophy',
        perms: ['view_all', 'view_online', 'view_offline'],
    },
    {
        id: 'shop',
        label: 'متجر الأسلحة',
        icon: 'fa-solid fa-shop',
        perms: ['shop_purchase', 'shop_manage', 'shop_view'],
    },
    {
        id: 'dirty',
        label: 'الأموال القذرة',
        icon: 'fa-solid fa-sack-dollar',
        perms: ['dirty_view', 'dirty_withdraw'],
    },
    {
        id: 'outfit',
        label: 'لبس العصابة',
        icon: 'fa-solid fa-shirt',
        perms: ['outfit_set', 'outfit_wear', 'outfit_dress_nearby', 'outfit_dress_all'],
    },
];

/* ════════════════════════════════════════════
   GANG ADMIN CATEGORIES
════════════════════════════════════════════ */
const ADMIN_CATEGORIES = [
    { id: 'admin-overview', label: 'الرئيسية',       icon: 'fa-solid fa-chart-pie',            perms: ['open_panel'] },
    { id: 'admin-message',  label: 'رسالة عامة',     icon: 'fa-solid fa-bullhorn',             perms: ['message_all_gangs'] },
    { id: 'admin-treasury', label: 'الخزنات',      icon: 'fa-solid fa-vault',                perms: ['view_all_treasury'] },
    { id: 'admin-warnings', label: 'التحذيرات',    icon: 'fa-solid fa-triangle-exclamation', perms: ['add_warning', 'remove_warning'] },
    { id: 'admin-ranking',  label: 'التصنيف والنقاط', icon: 'fa-solid fa-trophy',          perms: ['view_ranking', 'add_points', 'remove_points', 'reset_playtime'] },
    { id: 'admin-members',  label: 'الأعضاء',       icon: 'fa-solid fa-users',                perms: ['view_members'] },
    { id: 'admin-bulk',     label: 'سحب وعتاد',     icon: 'fa-solid fa-bolt',                 perms: ['pull_gang', 'give_weapon_gang'] },
    { id: 'admin-hire',     label: 'التوظيف',      icon: 'fa-solid fa-user-shield',          perms: ['hire_gang_admin'] },
    { id: 'admin-territory',label: 'استحلال المناطق', icon: 'fa-solid fa-crosshairs',         perms: ['territory_control'] },
    { id: 'admin-shops',    label: 'المتاجر والخزائن', icon: 'fa-solid fa-store',              perms: ['shop_control'] },
    { id: 'admin-treasure', label: 'حساب الكنز المفقود', icon: 'fa-solid fa-skull',               perms: ['treasure_control'] },
];

/* ════════════════════════════════════════════
    VUE APP
════════════════════════════════════════════ */

const APP_TEMPLATE = `
<div class="app-runtime-root">
<!-- ══════════ GANG SELECTOR ══════════ -->
    <transition name="zoom">
        <div class="selector-overlay" v-if="gangSelector.show">
            <div class="selector-box">
                <div class="selector-title">اختر العصابة</div>
                <div class="selector-grid">
                    <div class="selector-card" v-for="g in gangSelector.gangs" :key="g.id"
                         @click="selectGang(g)">
                        <img :src="g.logo" class="selector-logo" loading="eager" decoding="async">
                        <div class="selector-name" :style="{color: g.color}">{{ g.label }}</div>
                    </div>
                </div>
            </div>
        </div>
    </transition>

    <!-- ══════════ MAIN UI ══════════ -->
    <transition name="fade">
        <div id="mainContainer" v-if="show && !gangSelector.show">

            <!-- ▸ HEADER -->
            <div class="header">
                <div class="header-glow-orb"></div>

                <!-- اليمين: لوقو العصابة -->
                <div class="header-right">
                    <img :src="gang.logo" class="header-logo" loading="eager" decoding="async">
                </div>

                <!-- النص: اسم العصابة -->
                <div class="header-text">
                    <h2 class="header-gang-name" :style="{color: '#fff', textShadow: '0 0 28px ' + gang.color + '88'}">
                        {{ gang.label }}
                    </h2>
                    <span class="header-sub">لوحة الإدارة</span>
                </div>

                <!-- زر الإغلاق -->
                <button class="close-btn" @click="closeUi">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>


            <!-- ▸ BODY -->
            <div class="body-layout">

                <!-- ── Sidebar ── -->
                <div class="sidebar">
                    <div class="categories-label">الأقسام</div>
                    <div class="sidebar-list">
                        <div v-for="cat in visibleCategories" :key="cat.id"
                             :class="['sidebar-item', {active: activeCategory === cat.id}]"
                             @click="switchCategory(cat.id)">
                            <i :class="cat.icon"></i>
                            <span>{{ cat.label }}</span>
                        </div>
                    </div>
                </div>

                <!-- ── Main Content ── -->
                <div class="main-content">

                    <!-- ═ Warning Banner ═ -->
                    <transition name="slide-down">
                        <div class="gang-warning-banner" v-if="gang.warnings && gang.warnings.length > 0"
                             @click="warningDetail.warning = gang.warnings[0]; warningDetail.show = true">
                            <i class="fa-solid fa-triangle-exclamation"></i>
                            <span>{{ gang.warnings.length > 1 ? gang.warnings.length + ' تحذيرات نشطة' : 'تحذير نشط' }} — اضغط للتفاصيل</span>
                            <i class="fa-solid fa-chevron-left wbn-arrow"></i>
                        </div>
                    </transition>

                    <!-- ════ الرئيسية ════ -->
                    <div v-if="activeCategory === 'home'" class="cat-home">

                        <!-- Stats Bar -->
                        <div class="stats-row">
                            <div class="stat-card">
                                <div class="stat-val">{{ totalHours }}<span class="stat-unit">س</span> {{ totalMinutes }}<span class="stat-unit">د</span></div>
                                <div class="stat-lbl">تواجد العصابة</div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-val">{{ onlineCount }}</div>
                                <div class="stat-lbl">متصل الآن</div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-val">{{ totalMembers }}</div>
                                <div class="stat-lbl">إجمالي الأعضاء</div>
                            </div>
                        </div>

                        <!-- Top 5 -->
                        <div class="top5-box" v-if="dashboard.top5 && dashboard.top5.length">
                            <div class="section-label"><i class="fa-solid fa-trophy"></i> توب 5 تواجداً</div>
                            <div class="top5-list">
                                <div class="top5-row" v-for="(p, i) in dashboard.top5" :key="i">
                                    <div class="top5-rank" :class="'rank-' + (i+1)"># {{ i + 1 }}</div>
                                    <div class="top5-name">{{ p.name }}</div>
                                    <div class="top5-time">{{ p.hours }}س {{ p.minutes }}د</div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- ════ الأعضاء ════ -->
                    <div v-if="activeCategory === 'members'" class="cat-members">

                        <!-- Tabs -->
                        <div class="members-tabs">
                            <button :class="['tab-btn', {active: home.tab === 'all'}]"     @click="loadMembers('all')">الكل</button>
                            <button :class="['tab-btn', {active: home.tab === 'online'}]"  @click="loadMembers('online')" v-if="gang.perms.view_online">متصلين</button>
                            <button :class="['tab-btn', {active: home.tab === 'offline'}]" @click="loadMembers('offline')" v-if="gang.perms.view_offline">اوفلاين</button>
                        </div>

                        <!-- Search -->
                        <div class="search-box">
                            <i class="fa-solid fa-magnifying-glass"></i>
                            <input v-model="home.search" placeholder="بحث بالاسم أو ID أو الرتبة...">
                        </div>

                        <!-- Members List -->
                        <div class="members-list">
                            <div class="empty-placeholder" v-if="filteredMembers.length === 0">
                                <i class="fa-solid fa-users-slash"></i>
                                <span>لا يوجد أعضاء</span>
                            </div>
                            <div class="member-card"
                                 :class="{selected: home.selectedMember === m}"
                                 @click="home.selectedMember = (home.selectedMember === m ? null : m)"
                                 v-for="m in filteredMembers" :key="m.cid">

                                <!-- صف المعلومات -->
                                <div class="mc-row">
                                    <span class="member-online-dot" :class="{online: m.online}"></span>
                                    <img :src="m.avatar" class="member-avatar" loading="eager" decoding="async">
                                    <div class="member-info">
                                        <div class="member-name">{{ m.name }}</div>
                                        <div class="member-details">
                                            <span class="badge-id">{{ m.user_id || m.cid }}</span>
                                            <span class="badge-rank">{{ m.rank_label }}</span>
                                            <span class="badge-time"><i class="fa-solid fa-clock"></i> {{ m.hours }}س {{ m.minutes }}د</span>
                                        </div>
                                    </div>
                                    <i class="mc-arrow fa-solid fa-chevron-left" :class="{rotated: home.selectedMember === m}"></i>
                                </div>

                                <!-- أزرار الإجراءات (تظهر عند الضغط) -->
                                <transition name="slide-down">
                                    <div class="mc-actions-row" v-if="home.selectedMember === m" @click.stop>
                                        <button class="mc-action-btn promote"  v-if="gang.perms.promote_member"               @click.stop="promoteMember(m)"               title="ترقية"><i class="fa-solid fa-arrow-up"></i> ترقية</button>
                                        <button class="mc-action-btn demote"   v-if="gang.perms.demote_member"                @click.stop="demoteMember(m)"                title="تنزيل"><i class="fa-solid fa-arrow-down"></i> تنزيل</button>
                                        <button class="mc-action-btn weapon"   v-if="gang.perms.give_weapon_member && m.online" @click.stop="openWeaponPicker(m)"  title="سلاح"><i class="fa-solid fa-gun"></i> عتاد</button>
                                        <button class="mc-action-btn pull"     v-if="gang.perms.pull_member && m.online"        @click.stop="pullMember(m)"          title="سحب"><i class="fa-solid fa-location-arrow"></i> سحب</button>
                                        <button class="mc-action-btn danger"   v-if="gang.perms.fire_member"                    @click.stop="confirmAction('fireMember', m)" title="فصل"><i class="fa-solid fa-user-minus"></i> فصل</button>
                                    </div>
                                </transition>
                            </div>
                        </div>
                    </div>

                    <!-- ════ التوظيف ════ -->
                    <div v-if="activeCategory === 'hiring'" class="cat-hiring">

                        <!-- مربع ID اللاعب -->
                        <div class="input-section">
                            <div class="section-label"><i class="fa-solid fa-id-badge"></i> ايدي اللاعب (User ID)</div>
                            <div class="id-input-row">
                                <input class="gang-input" v-model="hiring.userId" type="number" placeholder="مثلاً: 5">
                            </div>
                        </div>

                        <!-- شبكة الرتب -->
                        <div class="input-section" v-if="gang.perms.hire_player || gang.perms.query_player">
                            <div class="section-label"><i class="fa-solid fa-award"></i> الرتبة (للتوظيف)</div>
                            <div class="rank-grid">
                                <div v-for="(r, i) in gang.ranks" :key="r.code"
                                     :class="['rank-card', {selected: hiring.selectedRank && hiring.selectedRank.code === r.code}]"
                                     @click="hiring.selectedRank = r">
                                    <span class="rank-num">{{ i + 1 }}</span>
                                    <span class="rank-lbl">{{ r.label }}</span>
                                </div>
                            </div>
                        </div>

                        <!-- أزرار الإجراءات -->
                        <div class="hiring-actions">
                            <button class="hire-btn info"    v-if="gang.perms.query_player"  @click="queryPlayer"  :disabled="!hiring.userId">
                                <i class="fa-solid fa-magnifying-glass"></i> استعلام
                            </button>
                            <button class="hire-btn success" v-if="gang.perms.hire_player"   @click="hirePlayer"   :disabled="!hiring.userId || !hiring.selectedRank">
                                <i class="fa-solid fa-user-plus"></i> توظيف
                            </button>
                            <button class="hire-btn danger"  v-if="gang.perms.fire_player"   @click="confirmAction('firePlayer', null)" :disabled="!hiring.userId">
                                <i class="fa-solid fa-user-minus"></i> فصل
                            </button>
                        </div>

                        <!-- نتيجة الاستعلام -->
                        <transition name="zoom">
                            <div class="query-result-card" v-if="hiring.queryResult">
                                <div class="qr-header">
                                    <img :src="hiring.queryResult.avatar" class="qr-avatar">
                                    <div class="qr-info">
                                        <div class="qr-name">{{ hiring.queryResult.name }}</div>
                                        <div class="qr-meta">
                                            <span class="badge-id">ID: {{ hiring.queryResult.user_id || hiring.queryResult.cid }}</span>
                                            <span :class="['badge-member', hiring.queryResult.is_member ? 'yes' : 'no']">
                                                {{ hiring.queryResult.is_member ? 'عضو' : 'ليس عضواً' }}
                                            </span>
                                        </div>
                                        <div class="qr-rank">{{ hiring.queryResult.rank_label }}</div>
                                        <div class="qr-time"><i class="fa-solid fa-clock"></i> {{ hiring.queryResult.hours }}س {{ hiring.queryResult.minutes }}د</div>
                                    </div>
                                </div>
                                <!-- أزرار من الكرت -->
                                <div class="qr-actions" v-if="hiring.queryResult.is_member">
                                    <button class="qr-btn promote" v-if="gang.perms.promote_member" @click="promoteMemberByCid(hiring.queryResult)">
                                        <i class="fa-solid fa-chevron-up"></i> ترقية
                                    </button>
                                    <button class="qr-btn demote"  v-if="gang.perms.demote_member"  @click="demoteMemberByCid(hiring.queryResult)">
                                        <i class="fa-solid fa-chevron-down"></i> تنزيل
                                    </button>
                                    <button class="qr-btn weapon"  v-if="gang.perms.give_weapon_member" @click="openWeaponPickerForQuery">
                                        <i class="fa-solid fa-gun"></i> عتاد
                                    </button>
                                </div>
                            </div>
                        </transition>
                    </div>

                    <!-- ════ العمليات الجماعية ════ -->
                    <div v-if="activeCategory === 'bulk'" class="cat-bulk">

                        <!-- رسالة للجميع -->
                        <div class="bulk-section" v-if="gang.perms.message_all">
                            <div class="section-label"><i class="fa-solid fa-bullhorn"></i> رسالة لجميع الأعضاء</div>
                            <textarea class="gang-textarea" v-model="bulk.message" placeholder="اكتب الرسالة هنا..." maxlength="200"></textarea>
                            <button class="bulk-btn info" @click="sendMessageAll">
                                <i class="fa-solid fa-paper-plane"></i> إرسال
                            </button>
                        </div>

                        <!-- سحب الجميع -->
                        <div class="bulk-section" v-if="gang.perms.pull_all">
                            <div class="section-label"><i class="fa-solid fa-users-rays"></i> سحب جميع الأعضاء المتصلين</div>
                            <button class="bulk-btn warn" @click="confirmAction('pullAll', null)">
                                <i class="fa-solid fa-location-arrow"></i> سحب الجميع
                            </button>
                        </div>

                        <!-- عتاد للجميع -->
                        <div class="bulk-section" v-if="gang.perms.give_weapon_all">
                            <div class="section-label"><i class="fa-solid fa-gun"></i> توزيع سلاح على الجميع</div>
                            <div class="weapon-grid">
                                <div v-for="w in gang.weapons" :key="w.weapon"
                                     :class="['weapon-card', {selected: bulk.selectedWeapon && bulk.selectedWeapon.weapon === w.weapon}]"
                                     @click="bulk.selectedWeapon = w">
                                    <i class="fa-solid fa-gun"></i>
                                    <span>{{ w.label }}</span>
                                    <small>{{ w.ammo }}x</small>
                                </div>
                            </div>
                            <button class="bulk-btn danger" :disabled="!bulk.selectedWeapon" @click="giveWeaponAll">
                                <i class="fa-solid fa-box-open"></i> توزيع على الجميع
                            </button>
                        </div>
                    </div>

                    <!-- ════ الخزنة ════ -->
                    <div v-if="activeCategory === 'treasury'" class="cat-treasury">

                        <!-- الرصيد -->
                        <div class="treasury-balance-card" v-if="gang.perms.treasury_view">
                            <div class="tb-label">رصيد الخزنة</div>
                            <div class="tb-amount" :style="{color: gang.color || '#4d7fff'}">
                                {{ treasury.balance.toLocaleString() }}<span class="tb-currency">$</span>
                            </div>
                        </div>

                        <!-- إيداع / سحب -->
                        <div class="treasury-btns">
                            <button class="t-big-btn deposit" v-if="gang.perms.treasury_deposit" @click="depositTreasury">
                                <i class="fa-solid fa-arrow-down-to-line"></i>
                                <span>إيداع</span>
                            </button>
                            <button class="t-big-btn withdraw" v-if="gang.perms.treasury_withdraw" @click="withdrawTreasury">
                                <i class="fa-solid fa-arrow-up-from-line"></i>
                                <span>سحب</span>
                            </button>
                        </div>

                        <!-- الأموال القذرة من المتجر -->
                        <!-- تم نقلها إلى تبويب مستقل -->

                        <!-- سجل العمليات -->
                        <div class="treasury-log" v-if="gang.perms.treasury_log && treasury.log.length > 0">
                            <div class="section-label"><i class="fa-solid fa-scroll"></i> سجل العمليات</div>
                            <div class="log-list">
                                <div class="log-row" v-for="entry in treasury.log" :key="entry.id"
                                     :class="entry.type">
                                    <div class="log-icon">
                                        <i :class="entry.type === 'deposit' ? 'fa-solid fa-plus' : 'fa-solid fa-minus'"></i>
                                    </div>
                                    <div class="log-info">
                                        <div class="log-by">{{ entry.by_name }} <span class="log-cid" v-if="entry.by_cid">[{{ entry.by_cid }}]</span></div>
                                        <div class="log-date">{{ entry.created_at }}</div>
                                    </div>
                                    <div class="log-amount" :class="entry.type">
                                        {{ entry.type === 'deposit' ? '+' : '-' }}{{ Number(entry.amount).toLocaleString() }}$
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- ════ التصنيف ════ -->
                    <div v-if="activeCategory === 'ranking'" class="cat-ranking">

                        <!-- تبويبات: نقاط / تواجد -->
                        <div class="rank-tabs">
                            <button class="rank-tab-btn"
                                    :class="{active: ranking.tab === 'points'}"
                                    @click="ranking.tab = 'points'">
                                <i class="fa-solid fa-star"></i> النقاط
                            </button>
                            <button class="rank-tab-btn"
                                    :class="{active: ranking.tab === 'playtime'}"
                                    @click="ranking.tab = 'playtime'">
                                <i class="fa-solid fa-clock"></i> التواجد
                            </button>
                            <button class="rank-refresh-btn" @click="loadRanking" :disabled="ranking.loading">
                                <i class="fa-solid fa-rotate" :class="{'fa-spin': ranking.loading}"></i>
                            </button>
                        </div>

                        <!-- قائمة التصنيف -->
                        <div class="rank-list" v-if="!ranking.loading && ranking.list.length > 0">
                            <template v-if="ranking.tab === 'points'">
                                <div v-for="(g, idx) in rankingByPoints"
                                     :key="'pts-'+g.id"
                                     class="gr-row"
                                     :class="{self: g.is_self, gold: idx===0, silver: idx===1, bronze: idx===2}">
                                    <div class="gr-pos">
                                        <i v-if="idx===0" class="fa-solid fa-crown gr-crown gold"></i>
                                        <i v-else-if="idx===1" class="fa-solid fa-crown gr-crown silver"></i>
                                        <i v-else-if="idx===2" class="fa-solid fa-crown gr-crown bronze"></i>
                                        <span v-else>{{ idx + 1 }}</span>
                                    </div>
                                    <img class="gr-logo" :src="g.logo" onerror="this.style.display='none'" />
                                    <div class="gr-info">
                                        <div class="gr-name" :style="{color: g.color}">{{ g.label }}</div>
                                        <div class="gr-meta">
                                            <span><i class="fa-solid fa-users"></i> {{ g.members }} عضو</span>
                                            <span><i class="fa-solid fa-clock"></i> {{ g.playtime_h }}س {{ g.playtime_m }}د</span>
                                        </div>
                                    </div>
                                    <div class="gr-score pts">
                                        <span class="gr-score-val" :style="{color: g.color}">{{ (g.points||0).toLocaleString() }}</span>
                                        <span class="gr-score-lbl">نقطة</span>
                                    </div>
                                </div>
                            </template>
                            <template v-if="ranking.tab === 'playtime'">
                                <div v-for="(g, idx) in rankingByPlaytime"
                                     :key="'pt-'+g.id"
                                     class="gr-row"
                                     :class="{self: g.is_self, gold: idx===0, silver: idx===1, bronze: idx===2}">
                                    <div class="gr-pos">
                                        <i v-if="idx===0" class="fa-solid fa-crown gr-crown gold"></i>
                                        <i v-else-if="idx===1" class="fa-solid fa-crown gr-crown silver"></i>
                                        <i v-else-if="idx===2" class="fa-solid fa-crown gr-crown bronze"></i>
                                        <span v-else>{{ idx + 1 }}</span>
                                    </div>
                                    <img class="gr-logo" :src="g.logo" onerror="this.style.display='none'" />
                                    <div class="gr-info">
                                        <div class="gr-name" :style="{color: g.color}">{{ g.label }}</div>
                                        <div class="gr-meta">
                                            <span><i class="fa-solid fa-users"></i> {{ g.members }} عضو</span>
                                            <span><i class="fa-solid fa-star"></i> {{ (g.points||0).toLocaleString() }} نقطة</span>
                                        </div>
                                    </div>
                                    <div class="gr-score time">
                                        <span class="gr-score-val">{{ g.playtime_h }}<small>س</small></span>
                                        <span class="gr-score-lbl">{{ g.playtime_m }} دقيقة</span>
                                    </div>
                                </div>
                            </template>
                        </div>

                        <!-- loading -->
                        <div class="rank-loading" v-if="ranking.loading">
                            <i class="fa-solid fa-circle-notch fa-spin"></i>
                            <span>جارٍ تحميل التصنيف…</span>
                        </div>

                        <!-- فارغ -->
                        <div class="rank-empty" v-if="!ranking.loading && ranking.list.length === 0">
                            <i class="fa-solid fa-trophy"></i>
                            <span>لا يوجد بيانات</span>
                        </div>

                    </div>

                    <!-- ════ متجر الأسلحة ════ -->
                    <div v-if="activeCategory === 'shop'" class="cat-shop">

                        <!-- Loading -->
                        <div class="shop-loading" v-if="shopManage.loading">
                            <i class="fa-solid fa-circle-notch fa-spin"></i>
                            <span>جاري التحميل...</span>
                        </div>

                        <template v-else>

                            <!-- ── رأس العصابة ── -->
                            <div class="shop-gang-header" :style="{'--gang-color': gang.color || '#4d7fff'}">
                                <div class="sgh-logo-wrap">
                                    <img v-if="gang.logo" :src="gang.logo" class="sgh-logo">
                                    <div v-else class="sgh-logo-fallback">
                                        <i class="fa-solid fa-shield-halved"></i>
                                    </div>
                                </div>
                                <div class="sgh-info">
                                    <div class="sgh-gang-name" :style="{color: gang.color || '#4d7fff'}">{{ gang.label }}</div>
                                    <div class="sgh-subtitle"><i class="fa-solid fa-shop"></i> متجر الأسلحة</div>
                                </div>
                                <div class="sgh-status-pill owned" v-if="shopManage.owned">
                                    <i class="fa-solid fa-circle-check"></i> نشط
                                </div>
                                <div class="sgh-status-pill locked" v-else-if="shopManage.current_points < shopManage.required_points">
                                    <i class="fa-solid fa-lock"></i> مقفل
                                </div>
                                <div class="sgh-status-pill available" v-else>
                                    <i class="fa-solid fa-store"></i> متاح
                                </div>
                            </div>

                            <!-- ── مقفل: لم تُستحل منطقة بعد ── -->
                            <div v-if="!shopManage.owned && !shopManage.territory_owned"
                                 class="shop-lock-card">
                                <div class="slc-icon"><i class="fa-solid fa-location-crosshairs"></i></div>
                                <div class="slc-body">
                                    <div class="slc-title">المتجر مقفل</div>
                                    <div class="slc-desc">-<b>يجب استحلال منطقة أولاً من</b></div>
                                </div>
                                <div class="slc-pts">
                                    <span class="slc-pts-label">الحالة</span>
                                    <span class="slc-pts-val">غير متاح</span>
                                </div>
                            </div>

                            <!-- ── مقفل: نقاط غير كافية ── -->
                            <div v-else-if="!shopManage.owned && shopManage.current_points < shopManage.required_points"
                                 class="shop-lock-card">
                                <div class="slc-icon"><i class="fa-solid fa-lock"></i></div>
                                <div class="slc-body">
                                    <div class="slc-title">المتجر مقفل</div>
                                    <div class="slc-desc">تحتاج <b>{{ shopManage.required_points.toLocaleString() }}</b> نقطة لفتح خيار الشراء</div>
                                </div>
                                <div class="slc-pts">
                                    <span class="slc-pts-label">نقاطك الحالية</span>
                                    <span class="slc-pts-val" :style="{color: gang.color}">{{ shopManage.current_points.toLocaleString() }}</span>
                                </div>
                            </div>

                            <!-- ── متاح للشراء ── -->
                            <div v-else-if="!shopManage.owned" class="shop-available-card">
                                <div class="sac-left">
                                    <div class="sac-icon"><i class="fa-solid fa-store"></i></div>
                                    <div>
                                        <div class="sac-title">المتجر متاح للشراء</div>
                                        <div class="sac-cost">التكلفة: <b>{{ shopManage.buy_cost.toLocaleString() }}$</b> من خزنة العصابة</div>
                                    </div>
                                </div>
                                <button class="shop-purchase-btn" v-if="gang.perms.shop_purchase"
                                        :style="{background: 'linear-gradient(135deg,'+gang.color+','+gang.color+'bb)'}"
                                        @click="shopPurchaseNow">
                                    <i class="fa-solid fa-bag-shopping"></i> شراء الآن
                                </button>
                                <div class="shop-no-perm" v-else>
                                    <i class="fa-solid fa-shield-halved"></i> لا تملك صلاحية الشراء
                                </div>
                            </div>

                            <!-- ── مفتوح: إدارة المخزون ── -->
                            <div v-else class="shop-manage-section">
                                <div class="shop-items-grid">
                                    <div class="shop-item-card"
                                         v-for="item in shopManage.items"
                                         :key="item.weapon"
                                         :style="{'--gang-color': gang.color || '#4d7fff'}">

                                        <!-- اسم + مخزون -->
                                        <div class="sic-top">
                                            <div class="sic-icon-wrap">
                                                <i class="fa-solid fa-gun"></i>
                                            </div>
                                            <div class="sic-meta">
                                                <span class="sic-name">{{ item.label }}</span>
                                                <span :class="['sic-stock', item.stock <= 0 ? 'empty' : item.stock <= 5 ? 'low' : 'ok']">
                                                    <i class="fa-solid fa-cubes"></i> {{ item.stock }} قطعة
                                                </span>
                                            </div>
                                        </div>

                                        <!-- الأسعار -->
                                        <div class="sic-price-row">
                                            <div class="sic-price-block">
                                                <span class="sic-price-lbl">سعر البيع</span>
                                                <span class="sic-price-val">{{ item.price.toLocaleString() }}$</span>
                                            </div>
                                            <div class="sic-divider"></div>
                                            <div class="sic-restock-block">
                                                <span class="sic-price-lbl">تكلفة التعبئة</span>
                                                <span class="sic-restock-val">{{ (item.restock_price * item.restock_amount).toLocaleString() }}$</span>
                                            </div>
                                            <div class="sic-divider"></div>
                                            <div class="sic-qty-block">
                                                <span class="sic-price-lbl">الكمية</span>
                                                <span class="sic-qty-val">+{{ item.restock_amount }}</span>
                                            </div>
                                        </div>

                                        <!-- إجراءات المدير -->
                                        <div class="sic-actions" v-if="gang.perms.shop_manage">
                                            <div class="sic-price-edit">
                                                <input class="gang-input sic-price-input"
                                                       type="number" min="1"
                                                       v-model="shopManage.priceInputs[item.weapon]"
                                                       placeholder="سعر جديد...">
                                                <button class="sic-set-btn" @click="shopSetWeaponPrice(item)">
                                                    <i class="fa-solid fa-tag"></i> تحديث
                                                </button>
                                            </div>
                                            <button class="sic-restock-btn" @click="shopRestockWeapon(item)">
                                                <i class="fa-solid fa-rotate-right"></i>
                                                إعادة تعبئة (+{{ item.restock_amount }})
                                            </button>
                                        </div>

                                    </div>
                                </div>
                            </div>

                        </template>
                    </div>

                    <!-- ════ الأموال القذرة ════ -->
                    <div v-if="activeCategory === 'dirty'" class="cat-dirty">

                        <!-- بطاقة الرصيد القذر -->
                        <div class="dirty-hero-card" v-if="gang.perms.dirty_view">
                            <div class="dirty-hero-icon"><i class="fa-solid fa-sack-dollar"></i></div>
                            <div class="dirty-hero-label">إيرادات المتجر (أموال قذرة)</div>
                            <div class="dirty-hero-balance">
                                {{ dirtyTreasury.balance.toLocaleString() }}<span class="dirty-hero-currency">$</span>
                            </div>
                        </div>

                        <!-- أزرار السحب -->
                        <div class="dirty-actions" v-if="gang.perms.dirty_withdraw && dirtyTreasury.balance > 0">
                            <button class="dirty-btn-all" @click="withdrawDirtyAll">
                                <i class="fa-solid fa-hand-holding-dollar"></i> سحب الكل
                            </button>
                            <div class="dirty-partial-row">
                                <input
                                    type="number"
                                    class="dirty-input"
                                    v-model="dirtyTreasury.dirtyWithdrawAmt"
                                    placeholder="مبلغ جزئي..."
                                    min="1"
                                    :max="dirtyTreasury.balance"
                                />
                                <button class="dirty-btn-partial" @click="withdrawDirtyPartial">
                                    <i class="fa-solid fa-coins"></i> سحب
                                </button>
                            </div>
                        </div>

                        <!-- رسالة الرصيد صفر -->
                        <div class="dirty-empty" v-if="gang.perms.dirty_withdraw && dirtyTreasury.balance <= 0">
                            <i class="fa-solid fa-sack-xmark"></i>
                            <span>لا توجد أموال قذرة حالياً</span>
                        </div>

                        <!-- سجل الأموال القذرة -->
                        <div class="dirty-log-section" v-if="gang.perms.dirty_view && dirtyTreasury.log.length > 0">
                            <div class="section-label"><i class="fa-solid fa-scroll"></i> سجل الأموال القذرة</div>
                            <div class="dirty-log-list">
                                <div class="dirty-log-row" v-for="entry in dirtyTreasury.log" :key="entry.id"
                                     :class="entry.log_type">
                                    <div class="dirty-log-icon">
                                        <i :class="entry.log_type === 'revenue' ? 'fa-solid fa-arrow-trend-up' : 'fa-solid fa-arrow-up-from-line'"></i>
                                    </div>
                                    <div class="dirty-log-info">
                                        <div class="dirty-log-who">
                                            {{ entry.by_name }}
                                            <span class="dirty-log-cid" v-if="entry.by_cid">[{{ entry.by_cid }}]</span>
                                        </div>
                                        <div class="dirty-log-note" v-if="entry.note">{{ entry.note }}</div>
                                        <div class="dirty-log-date">{{ entry.created_at }}</div>
                                    </div>
                                    <div class="dirty-log-amount" :class="entry.log_type">
                                        {{ entry.log_type === 'revenue' ? '+' : '-' }}{{ Number(entry.amount).toLocaleString() }}$
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Loading -->
                        <div class="dirty-loading" v-if="dirtyTreasury.loading">
                            <i class="fa-solid fa-spinner fa-spin"></i>
                        </div>

                    </div>

                    <!-- ════════════ لبس العصابة ════════════ -->
                    <div v-if="activeCategory === 'outfit'" class="cat-outfit">

                        <!-- Loading -->
                        <div class="outfit-loading-state" v-if="outfit.loading">
                            <i class="fa-solid fa-circle-notch fa-spin"></i>
                            <span>جاري التحميل...</span>
                        </div>

                        <template v-else>

                            <!-- زر تعيين / تحديث السكن — outfit_set فقط -->
                            <div class="bulk-section" v-if="gang.perms.outfit_set">
                                <div class="section-label">
                                    <i class="fa-solid fa-user-pen"></i> سكن العصابة
                                </div>
                                <button class="bulk-btn info" @click="setGangOutfit">
                                    <i class="fa-solid fa-floppy-disk"></i>
                                    {{ outfit.hasOutfit ? 'تحديث السكن' : 'جعل السكن الحالي سكن العصابة' }}
                                </button>
                            </div>

                            <!-- خيارات اللبس — كل زر ببرمشن مستقل -->
                            <div class="bulk-section"
                                 v-if="outfit.hasOutfit && (gang.perms.outfit_wear || gang.perms.outfit_dress_nearby || gang.perms.outfit_dress_all)">
                                <div class="section-label">
                                    <i class="fa-solid fa-shirt"></i> خيارات اللبس
                                </div>

                                <!-- لبس سكن العصابة — outfit_wear -->
                                <button class="bulk-btn success"
                                        v-if="gang.perms.outfit_wear"
                                        @click="wearGangOutfit">
                                    <i class="fa-solid fa-tshirt"></i>
                                    لبس سكن العصابة
                                </button>

                                <!-- الباس شخص بالايدي — outfit_dress_nearby -->
                                <button class="bulk-btn warn"
                                        v-if="gang.perms.outfit_dress_nearby"
                                        @click="dressNearbyPlayer">
                                    <i class="fa-solid fa-user-check"></i>
                                    الباس شخص بالايدي سكن العصابة
                                </button>

                                <!-- الباس العصابة كلها — outfit_dress_all -->
                                <button class="bulk-btn danger"
                                        v-if="gang.perms.outfit_dress_all"
                                        @click="dressGangAll">
                                    <i class="fa-solid fa-people-group"></i>
                                    الباس العصابة كلها اللبس
                                </button>
                            </div>

                            <!-- رسالة لا يوجد سكن — لمن يملك outfit_wear فقط بدون outfit_set -->
                            <div class="dirty-empty"
                                 v-if="!outfit.hasOutfit && !gang.perms.outfit_set">
                                <i class="fa-solid fa-shirt"></i>
                                <span>لم يُعيَّن سكن للعصابة بعد، تواصل مع المدير</span>
                            </div>

                            <!-- رسالة للمدير إذا لم يُعيَّن سكن بعد -->
                            <div class="dirty-empty"
                                 v-if="!outfit.hasOutfit && gang.perms.outfit_set">
                                <i class="fa-solid fa-user-slash"></i>
                                <span>لم يُعيَّن سكن بعد — اضغط الزر أعلى لتعيين لبسك الحالي</span>
                            </div>

                        </template>

                    </div>

                </div><!-- /main-content -->
            </div><!-- /body-layout -->
        </div><!-- /mainContainer -->
    </transition>

    <!-- ══════════ WEAPON PICKER MODAL ══════════ -->
    <transition name="zoom">
        <div class="modal-overlay" v-if="weaponPicker.show">
            <div class="modal-box">
                <div class="modal-title">اختر السلاح</div>
                <div class="weapon-grid modal-weapon-grid">
                    <div v-for="w in gang.weapons" :key="w.weapon"
                         :class="['weapon-card', {selected: weaponPicker.selected && weaponPicker.selected.weapon === w.weapon}]"
                         @click="weaponPicker.selected = w">
                        <i class="fa-solid fa-gun"></i>
                        <span>{{ w.label }}</span>
                        <small>{{ w.ammo }}x</small>
                    </div>
                </div>
                <div class="modal-footer">
                    <button class="m-confirm" :disabled="!weaponPicker.selected" @click="confirmWeapon">
                        <i class="fa-solid fa-check"></i> تأكيد
                    </button>
                    <button class="m-cancel" @click="weaponPicker.show = false">إلغاء</button>
                </div>
            </div>
        </div>
    </transition>

    <!-- ══════════ CONFIRM MODAL ══════════ -->
    <transition name="zoom">
        <div class="modal-overlay" v-if="confirm.show">
            <div class="modal-box confirm-modal">
                <div class="confirm-icon"><i :class="confirm.icon"></i></div>
                <div class="modal-title">{{ confirm.title }}</div>
                <div class="confirm-body" v-html="confirm.body"></div>
                <div class="confirm-amount-wrap" v-if="confirm.showAmountInput">
                    <input class="gang-input confirm-amount-input" v-model="confirm.amountInput"
                           :type="confirm.inputType || 'number'"
                           :placeholder="confirm.inputPlaceholder || 'أدخل المبلغ...'"
                           @keyup.enter="executeConfirm">
                </div>
                <div class="modal-footer">
                    <button :class="['m-confirm', confirm.confirmClass || 'danger']"
                            :disabled="confirm.showAmountInput && !parseInt(confirm.amountInput)"
                            @click="executeConfirm">
                        <i class="fa-solid fa-check"></i> {{ confirm.confirmLabel || 'تأكيد' }}
                    </button>
                    <button class="m-cancel" @click="confirm.show = false">إلغاء</button>
                </div>
            </div>
        </div>
    </transition>

    <!-- ══════════ BROADCAST NOTIFICATION ══════════ -->
    <transition name="broadcast-in">
        <div class="bc-overlay" v-if="broadcast.show">
            <div class="bc-box" :style="{'--gc': broadcast.gangColor}">
                <div class="bc-logo-wrap">
                    <img :src="broadcast.gangImage" class="bc-logo" v-if="broadcast.gangImage">
                    <div class="bc-logo-placeholder" v-else><i class="fa-solid fa-bullhorn"></i></div>
                    <div class="bc-logo-ring"></div>
                </div>
                <div class="bc-gang-name" :style="{color: broadcast.gangColor}">{{ broadcast.gangName }}</div>
                <div class="bc-divider">
                    <span class="bc-line"></span>
                    <i class="fa-solid fa-bullhorn bc-divider-icon" :style="{color: broadcast.gangColor}"></i>
                    <span class="bc-line"></span>
                </div>
                <div class="bc-message">{{ broadcast.message }}</div>
                <div class="bc-footer">
                    <i class="fa-solid fa-circle-user" :style="{color: broadcast.gangColor}"></i>
                    <span>{{ broadcast.senderName }}</span>
                </div>
                <div class="bc-progress">
                    <div class="bc-progress-bar" :style="{background: broadcast.gangColor}"></div>
                </div>
            </div>
        </div>
    </transition>

    <!-- ══════════ TOAST NOTIFICATIONS ══════════ -->
    <div id="notify-container"></div>

    <!-- ══════════ WARNING DETAIL MODAL ══════════ -->
    <transition name="zoom">
        <div class="modal-overlay" v-if="warningDetail.show" @click.self="warningDetail.show = false">
            <div class="modal-box warning-detail-modal">
            <div class="wdm-icon"><i class="fa-solid fa-triangle-exclamation"></i></div>
            <div class="modal-title" v-if="warningDetail.warning">{{ warningDetail.warning.title }}</div>
            <div class="wdm-body" v-if="warningDetail.warning">
                <div class="wdm-row" v-if="warningDetail.warning.reason">
                    <span class="wdm-lbl"><i class="fa-solid fa-align-right"></i> السبب</span>
                    <span class="wdm-val">{{ warningDetail.warning.reason }}</span>
                </div>
                <div class="wdm-row" v-if="warningDetail.warning.duration > 0">
                    <span class="wdm-lbl"><i class="fa-solid fa-calendar-days"></i> المدة</span>
                    <span class="wdm-val">{{ warningDetail.warning.duration }} يوم</span>
                </div>
                <div class="wdm-row">
                    <span class="wdm-lbl"><i class="fa-solid fa-user-shield"></i> صادر بواسطة</span>
                    <span class="wdm-val">{{ warningDetail.warning.by_name }}</span>
                </div>
                <div class="wdm-row">
                    <span class="wdm-lbl"><i class="fa-solid fa-clock"></i> التاريخ</span>
                    <span class="wdm-val">{{ warningDetail.warning.created_at }}</span>
                </div>
                <!-- navigate multiple warnings -->
                <div class="wdm-nav" v-if="gang.warnings.length > 1">
                    <div class="wdm-nav-label">تحذير {{ gang.warnings.indexOf(warningDetail.warning)+1 }} / {{ gang.warnings.length }}</div>
                    <div class="wdm-nav-btns">
                        <button class="wdm-nav-btn" :disabled="gang.warnings.indexOf(warningDetail.warning) <= 0"
                                @click="warningDetail.warning = gang.warnings[gang.warnings.indexOf(warningDetail.warning)-1]">
                            <i class="fa-solid fa-chevron-right"></i>
                        </button>
                        <button class="wdm-nav-btn" :disabled="gang.warnings.indexOf(warningDetail.warning) >= gang.warnings.length-1"
                                @click="warningDetail.warning = gang.warnings[gang.warnings.indexOf(warningDetail.warning)+1]">
                            <i class="fa-solid fa-chevron-left"></i>
                        </button>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="m-cancel" style="flex:1" @click="warningDetail.show = false">إغلاق</button>
            </div>
        </div>
    </div>
</transition>

<!-- ══════════ ADMIN PANEL ══════════ -->
<transition name="fade">
    <div id="adminContainer" v-if="adminPanel.show">

        <!-- ▸ HEADER -->
        <div class="header admin-header">
            <div class="header-glow-orb" style="background:radial-gradient(ellipse,rgba(231,76,60,.18) 0%,transparent 70%);"></div>
            <div class="header-right">
                <div class="admin-header-icon"><i class="fa-solid fa-shield-halved"></i></div>
            </div>
            <div class="header-text">
                <h2 class="header-gang-name">Gang Manager</h2>
                <span class="header-sub">Gang Admin Dashboard</span>
            </div>
            <button class="close-btn" @click="closeAdmin">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>

        <!-- ▸ BODY -->
        <div class="body-layout">

            <!-- ── Sidebar ── -->
            <div class="sidebar">
                <div class="categories-label">الأقسام</div>
                <div class="sidebar-list">
                    <div v-for="cat in adminVisibleCategories" :key="cat.id"
                         :class="['sidebar-item', {active: adminPanel.activeCategory === cat.id}]"
                         @click="adminSwitchCategory(cat.id)">
                        <i :class="cat.icon"></i>
                        <span>{{ cat.label }}</span>
                    </div>
                </div>
            </div>

            <!-- ── Main Content ── -->
            <div class="main-content">

                <!-- ════ الرئيسية ════ -->
                <div v-if="adminPanel.activeCategory === 'admin-overview'" class="cat-admin-overview">
                    <div class="section-label"><i class="fa-solid fa-chart-pie"></i> ملخص العصابات</div>
                    <div class="admin-gangs-grid">
                        <div class="admin-gang-card" v-for="g in adminPanel.gangs" :key="g.id"
                             :style="{'--gc': g.color || '#4d7fff'}">
                            <div class="agc-header">
                                <img :src="g.logo" class="agc-logo" loading="eager" decoding="async">
                                <div class="agc-info">
                                    <div class="agc-name" :style="{color: g.color}">{{ g.label }}</div>
                                    <div class="agc-badges">
                                        <span class="badge-id">{{ g.members }} عضو</span>
                                        <span class="badge-online-sm">{{ g.online }} متصل</span>
                                        <span class="badge-warn-sm" v-if="g.warning_count > 0">{{ g.warning_count }} تحذير</span>
                                    </div>
                                </div>
                            </div>
                            <div class="agc-stats">
                                <div class="agc-stat">
                                    <i class="fa-solid fa-vault"></i>
                                    <span>{{ Number(g.treasury || 0).toLocaleString() }}$</span>
                                </div>
                                <div class="agc-stat">
                                    <i class="fa-solid fa-star"></i>
                                    <span>{{ g.points || 0 }} نقطة</span>
                                </div>
                                <div class="agc-stat">
                                    <i class="fa-solid fa-clock"></i>
                                    <span>{{ g.playtime_h }}س {{ g.playtime_m }}د</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- ════ رسالة عامة ════ -->
                <div v-if="adminPanel.activeCategory === 'admin-message'" class="cat-admin-message">
                    <div class="section-label"><i class="fa-solid fa-bullhorn"></i> إرسال رسالة</div>
                    <div class="input-section">
                        <div class="section-label-sm">العصابة المستهدفة</div>
                        <div class="gang-pill-row">
                            <div :class="['gang-pill', {active: adminPanel.message.targetGangId === ''}]"
                                 @click="adminPanel.message.targetGangId = ''">
                                <i class="fa-solid fa-earth-americas"></i> الكل
                            </div>
                            <div v-for="g in adminPanel.gangs" :key="g.id"
                                 :class="['gang-pill', {active: adminPanel.message.targetGangId === g.id}]"
                                 :style="adminPanel.message.targetGangId === g.id ? {background: g.color+'22', borderColor: g.color} : {}"
                                 @click="adminPanel.message.targetGangId = g.id">
                                {{ g.label }}
                            </div>
                        </div>
                    </div>
                    <div class="input-section">
                        <div class="section-label-sm">نص الرسالة</div>
                        <textarea class="gang-textarea" v-model="adminPanel.message.text"
                                  placeholder="اكتب الرسالة هنا..." maxlength="300"></textarea>
                        <button class="bulk-btn info" :disabled="!adminPanel.message.text.trim()" @click="adminSendMessage">
                            <i class="fa-solid fa-paper-plane"></i> إرسال
                        </button>
                    </div>
                </div>

                <!-- ════ الخزنات ════ -->
                <div v-if="adminPanel.activeCategory === 'admin-treasury'" class="cat-admin-treasury">
                    <div class="section-label"><i class="fa-solid fa-vault"></i> خزنات جميع العصابات</div>
                    <div class="adm-treasury-list">
                        <div class="adm-treasury-row" v-for="g in adminPanel.gangs" :key="g.id">
                            <div class="adm-tr-info">
                                <img :src="g.logo" class="adm-tr-logo" loading="eager" decoding="async">
                                <span class="adm-tr-name" :style="{color: g.color}">{{ g.label }}</span>
                            </div>
                            <div class="adm-tr-balance" :style="{color: g.color}">
                                {{ Number(g.treasury || 0).toLocaleString() }}<span class="tb-currency">$</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- ════ التحذيرات ════ -->
                <div v-if="adminPanel.activeCategory === 'admin-warnings'" class="cat-admin-warnings">
                    <div class="section-label"><i class="fa-solid fa-triangle-exclamation"></i> إدارة التحذيرات</div>
                    <div class="gang-pill-row">
                        <div v-for="g in adminPanel.gangs" :key="g.id"
                             :class="['gang-pill', {active: adminPanel.warnings.selectedGangId === g.id}]"
                             :style="adminPanel.warnings.selectedGangId === g.id ? {background: g.color+'22', borderColor: g.color} : {}"
                             @click="adminSelectGangForWarnings(g.id)">
                            {{ g.label }}
                            <span class="pill-cnt warn" v-if="g.warning_count > 0">{{ g.warning_count }}</span>
                        </div>
                    </div>

                    <div class="warning-form" v-if="adminPanel.warnings.selectedGangId && adminPanel.perms.add_warning">
                        <div class="section-label-sm">إضافة تحذير جديد</div>
                        <input class="gang-input" v-model="adminPanel.warnings.form.title"
                               placeholder="عنوان التحذير..." maxlength="64">
                        <textarea class="gang-textarea sm" v-model="adminPanel.warnings.form.reason"
                                  placeholder="السبب..." maxlength="256"></textarea>
                        <div class="warn-form-row">
                            <input class="gang-input w-half" v-model="adminPanel.warnings.form.duration"
                                   type="number" min="0" placeholder="المدة (أيام — 0 = غير محدد)">
                            <button class="hire-btn danger" :disabled="!adminPanel.warnings.form.title.trim()"
                                    @click="adminAddWarning">
                                <i class="fa-solid fa-circle-exclamation"></i> إصدار تحذير
                            </button>
                        </div>
                    </div>

                    <div class="warnings-list" v-if="adminPanel.warnings.selectedGangId">
                        <div class="empty-placeholder" v-if="adminPanel.warnings.list.length === 0">
                            <i class="fa-solid fa-circle-check"></i>
                            <span>لا توجد تحذيرات</span>
                        </div>
                        <div class="warning-card" v-for="w in adminPanel.warnings.list" :key="w.id">
                            <div class="wc-header">
                                <i class="fa-solid fa-triangle-exclamation wc-icon"></i>
                                <div class="wc-info">
                                    <div class="wc-title">{{ w.title }}</div>
                                    <div class="wc-meta">
                                        <span>بواسطة: {{ w.by_name }}</span>
                                        <span v-if="w.duration > 0">المدة: {{ w.duration }} يوم</span>
                                        <span>{{ w.created_at }}</span>
                                    </div>
                                </div>
                                <button class="wc-del-btn" v-if="adminPanel.perms.remove_warning"
                                        @click="adminRemoveWarning(w.id)">
                                    <i class="fa-solid fa-trash"></i>
                                </button>
                            </div>
                            <div class="wc-reason" v-if="w.reason">{{ w.reason }}</div>
                        </div>
                    </div>
                </div>

                <!-- ════ التصنيف والنقاط ════ -->
                <div v-if="adminPanel.activeCategory === 'admin-ranking'" class="cat-admin-ranking">
                    <div class="section-label"><i class="fa-solid fa-trophy"></i> النقاط والتصنيف</div>

                    <div class="points-section" v-if="adminPanel.perms.add_points || adminPanel.perms.remove_points">
                        <div class="section-label-sm">إدارة نقاط عصابة</div>
                        <div class="gang-pill-row">
                            <div v-for="g in adminPanel.gangs" :key="g.id"
                                 :class="['gang-pill', {active: adminPanel.ranking.selectedGangId === g.id}]"
                                 :style="adminPanel.ranking.selectedGangId === g.id ? {background: g.color+'22', borderColor: g.color} : {}"
                                 @click="adminPanel.ranking.selectedGangId = g.id">
                                {{ g.label }}
                                <span class="pill-cnt pts">{{ g.points || 0 }}</span>
                            </div>
                        </div>
                        <div class="points-input-row" v-if="adminPanel.ranking.selectedGangId">
                            <input class="gang-input flex1" v-model="adminPanel.ranking.pointsInput"
                                   type="number" min="1" placeholder="عدد النقاط...">
                            <button class="hire-btn success" v-if="adminPanel.perms.add_points"
                                    :disabled="!adminPanel.ranking.pointsInput" @click="adminAddPoints">
                                <i class="fa-solid fa-plus"></i> إضافة
                            </button>
                            <button class="hire-btn danger" v-if="adminPanel.perms.remove_points"
                                    :disabled="!adminPanel.ranking.pointsInput" @click="adminRemovePoints">
                                <i class="fa-solid fa-minus"></i> خصم
                            </button>
                            <button class="hire-btn danger" v-if="adminPanel.perms.reset_playtime"
                                    @click="adminResetPlaytime">
                                <i class="fa-solid fa-clock-rotate-left"></i> تصفير التواجد
                            </button>
                        </div>
                    </div>

                    <div class="ranking-table" v-if="adminPanel.perms.view_ranking">
                        <div class="section-label-sm" style="margin-top:18px">
                            <i class="fa-solid fa-list-ol"></i> التصنيف الحالي
                            <button class="refresh-btn" @click="adminLoadRanking">
                                <i class="fa-solid fa-rotate"></i> تحديث
                            </button>
                        </div>
                        <div class="empty-placeholder" v-if="adminPanel.ranking.list.length === 0">
                            <i class="fa-solid fa-rotate" style="font-size:28px;opacity:.3"></i>
                            <span>اضغط تحديث لجلب التصنيف</span>
                        </div>
                        <div class="rank-row" v-for="(g, i) in adminPanel.ranking.list" :key="g.id">
                            <div class="rank-pos" :class="'rank-' + Math.min(i+1, 4)">#{{ i + 1 }}</div>
                            <img :src="g.logo" class="rank-logo" loading="eager" decoding="async">
                            <div class="rank-info">
                                <div class="rank-lbl-name" :style="{color: g.color}">{{ g.label }}</div>
                                <div class="rank-meta-row">
                                    <span><i class="fa-solid fa-clock"></i> {{ g.playtime_h }}س {{ g.playtime_m }}د</span>
                                    <span><i class="fa-solid fa-users"></i> {{ g.members }}</span>
                                </div>
                            </div>
                            <div class="rank-pts" :style="{color: g.color}">
                                {{ g.points }}<span class="rank-pts-lbl">نقطة</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- ════ الأعضاء ════ -->
                <div v-if="adminPanel.activeCategory === 'admin-members'" class="cat-admin-members">
                    <div class="section-label"><i class="fa-solid fa-users"></i> أعضاء العصابات</div>
                    <div class="gang-pill-row">
                        <div v-for="g in adminPanel.gangs" :key="g.id"
                             :class="['gang-pill', {active: adminPanel.members.selectedGangId === g.id}]"
                             :style="adminPanel.members.selectedGangId === g.id ? {background: g.color+'22', borderColor: g.color} : {}"
                             @click="adminLoadMembers(g.id)">
                            {{ g.label }}
                            <span class="pill-cnt">{{ g.members }}</span>
                        </div>
                    </div>
                    <div class="search-box" v-if="adminPanel.members.selectedGangId" style="margin-top:10px">
                        <i class="fa-solid fa-magnifying-glass"></i>
                        <input v-model="adminPanel.members.search" placeholder="بحث بالاسم أو ID أو الرتبة...">
                    </div>
                    <div class="members-list" v-if="adminPanel.members.selectedGangId" style="margin-top:8px">
                        <div class="empty-placeholder" v-if="adminFilteredMembers.length === 0">
                            <i class="fa-solid fa-users-slash"></i><span>لا يوجد أعضاء</span>
                        </div>
                        <div class="member-card"
                             :class="{selected: adminPanel.members.selectedMember === m}"
                             @click="adminPanel.members.selectedMember = (adminPanel.members.selectedMember === m ? null : m)"
                             v-for="m in adminFilteredMembers" :key="m.cid">
                            <div class="mc-row">
                                <span class="member-online-dot" :class="{online: m.online}"></span>
                                <img :src="m.avatar" class="member-avatar" loading="eager" decoding="async">
                                <div class="member-info">
                                    <div class="member-name">{{ m.name }}</div>
                                    <div class="member-details">
                                        <span class="badge-id">{{ m.user_id || m.cid }}</span>
                                        <span class="badge-rank">{{ m.rank_label }}</span>
                                        <span class="badge-time"><i class="fa-solid fa-clock"></i> {{ m.hours }}س {{ m.minutes }}د</span>
                                    </div>
                                </div>
                                <i class="mc-arrow fa-solid fa-chevron-left" :class="{rotated: adminPanel.members.selectedMember === m}"></i>
                            </div>

                            <transition name="slide-down">
                                <div class="mc-actions-row" v-if="adminPanel.members.selectedMember === m" @click.stop>
                                    <button class="mc-action-btn promote" v-if="adminPanel.perms.members_promote || adminPanel.perms.hire_gang_admin" @click.stop="adminPromoteMember(m)">
                                        <i class="fa-solid fa-arrow-up"></i> ترقية
                                    </button>
                                    <button class="mc-action-btn demote" v-if="adminPanel.perms.members_demote || adminPanel.perms.hire_gang_admin" @click.stop="adminDemoteMember(m)">
                                        <i class="fa-solid fa-arrow-down"></i> تنزيل
                                    </button>
                                    <button class="mc-action-btn weapon" v-if="(adminPanel.perms.members_give_weapon || adminPanel.perms.give_weapon_gang) && m.online" @click.stop="adminOpenWeaponPicker(m)">
                                        <i class="fa-solid fa-gun"></i> عتاد
                                    </button>
                                    <button class="mc-action-btn pull" v-if="(adminPanel.perms.members_pull || adminPanel.perms.pull_gang) && m.online" @click.stop="adminPullMember(m)">
                                        <i class="fa-solid fa-location-arrow"></i> سحب
                                    </button>
                                    <button class="mc-action-btn danger" v-if="adminPanel.perms.members_fire || adminPanel.perms.hire_gang_admin" @click.stop="adminFireMember(m)">
                                        <i class="fa-solid fa-user-minus"></i> فصل
                                    </button>
                                </div>
                            </transition>
                        </div>
                    </div>
                </div>

                <!-- ════ سحب وعتاد ════ -->
                <div v-if="adminPanel.activeCategory === 'admin-bulk'" class="cat-admin-bulk">
                    <div class="section-label"><i class="fa-solid fa-bolt"></i> سحب وعتاد</div>
                    <div class="input-section">
                        <div class="section-label-sm">اختر العصابة</div>
                        <div class="gang-pill-row">
                            <div v-for="g in adminPanel.gangs" :key="g.id"
                                 :class="['gang-pill', {active: adminPanel.bulk.selectedGangId === g.id}]"
                                 :style="adminPanel.bulk.selectedGangId === g.id ? {background: g.color+'22', borderColor: g.color} : {}"
                                 @click="adminPanel.bulk.selectedGangId = g.id">
                                {{ g.label }}
                            </div>
                        </div>
                    </div>
                    <div class="bulk-section" v-if="adminPanel.perms.pull_gang && adminPanel.bulk.selectedGangId">
                        <div class="section-label-sm"><i class="fa-solid fa-users-rays"></i> سحب الأعضاء المتصلين</div>
                        <button class="bulk-btn warn" @click="adminPullGang">
                            <i class="fa-solid fa-location-arrow"></i> سحب الجميع
                        </button>
                    </div>
                    <div class="bulk-section" v-if="adminPanel.perms.give_weapon_gang && adminPanel.bulk.selectedGangId">
                        <div class="section-label-sm"><i class="fa-solid fa-gun"></i> توزيع سلاح</div>
                        <div class="weapon-grid">
                            <div v-for="w in adminPanel.weapons" :key="w.weapon"
                                 :class="['weapon-card', {selected: adminPanel.bulk.selectedWeapon && adminPanel.bulk.selectedWeapon.weapon === w.weapon}]"
                                 @click="adminPanel.bulk.selectedWeapon = w">
                                <i class="fa-solid fa-gun"></i>
                                <span>{{ w.label }}</span>
                                <small>{{ w.ammo }}x</small>
                            </div>
                        </div>
                        <button class="bulk-btn danger" :disabled="!adminPanel.bulk.selectedWeapon"
                                @click="adminGiveWeaponGang">
                            <i class="fa-solid fa-box-open"></i> توزيع على الجميع
                        </button>
                    </div>
                </div>

                <!-- ════ المسؤولون ════ -->
                <div v-if="adminPanel.activeCategory === 'admin-hire'" class="cat-admin-hire">
                    <div class="section-label"><i class="fa-solid fa-user-shield"></i> إدارة المسؤولين</div>
                    <div class="input-section">
                        <div class="section-label-sm">اختر العصابة</div>
                        <div class="gang-pill-row">
                            <div v-for="g in adminPanel.gangs" :key="g.id"
                                 :class="['gang-pill', {active: adminPanel.hire.selectedGangId === g.id}]"
                                 :style="adminPanel.hire.selectedGangId === g.id ? {background: g.color+'22', borderColor: g.color} : {}"
                                 @click="adminPanel.hire.selectedGangId = g.id; adminPanel.hire.selectedRank = null">
                                {{ g.label }}
                            </div>
                        </div>
                    </div>
                    <div class="input-section">
                        <div class="section-label-sm"><i class="fa-solid fa-id-badge"></i> User ID اللاعب</div>
                        <input class="gang-input" v-model="adminPanel.hire.userId"
                               type="number" placeholder="مثلاً: 5">
                    </div>
                    <div class="input-section" v-if="adminSelectedGangForHire">
                        <div class="section-label-sm"><i class="fa-solid fa-award"></i> الرتبة</div>
                        <div class="rank-grid">
                            <div v-for="(r, i) in adminSelectedGangForHire.ranks" :key="r.code"
                                 :class="['rank-card', {selected: adminPanel.hire.selectedRank && adminPanel.hire.selectedRank.code === r.code}]"
                                 @click="adminPanel.hire.selectedRank = r">
                                <span class="rank-num">{{ i + 1 }}</span>
                                <span class="rank-lbl">{{ r.label }}</span>
                            </div>
                        </div>
                    </div>
                    <div class="hiring-actions">
                        <button class="hire-btn success"
                                :disabled="!adminPanel.hire.userId || !adminPanel.hire.selectedGangId || !adminPanel.hire.selectedRank"
                                @click="adminHire">
                            <i class="fa-solid fa-user-plus"></i> توظيف
                        </button>
                        <button class="hire-btn danger"
                                :disabled="!adminPanel.hire.userId || !adminPanel.hire.selectedGangId"
                                @click="adminFire">
                            <i class="fa-solid fa-user-minus"></i> فصل
                        </button>
                    </div>
                </div>

                <!-- ════ القتال على منطقة (أدمن) ════ -->
                <div v-if="adminPanel.activeCategory === 'admin-territory'" class="cat-territory cat-admin-territory">

                    <!-- loading -->
                    <div class="rank-loading" v-if="territory.loading">
                        <i class="fa-solid fa-circle-notch fa-spin"></i>
                        <span>جارٍ تحميل بيانات الاستحلال…</span>
                    </div>

                    <div v-if="!territory.loading">
                    <div class="terr-create-card">
                        <div class="section-label"><i class="fa-solid fa-crosshairs"></i> بدء استحلال جديد</div>
                        <div class="terr-form-grid">
                            <div class="terr-input-wrap">
                                <label>نطاق المنطقة (متر)</label>
                                <input class="gang-input" type="number" v-model.number="territory.radius"
                                       :min="territory.min_radius" :max="territory.max_radius">
                            </div>
                            <div class="terr-input-wrap">
                                <label>مدة الاستحلال (ثانية)</label>
                                <input class="gang-input" type="number" v-model.number="territory.seconds"
                                       :min="territory.min_seconds" :max="territory.max_seconds">
                            </div>
                        </div>
                        <button class="terr-start-btn" @click="adminStartTerritoryBattle">
                            <i class="fa-solid fa-bullseye"></i> بدء القتال على موقعك الحالي
                        </button>
                    </div>

                    <div class="terr-active-box" v-if="territory.activeZone">
                        <div class="terr-active-title">
                            <i class="fa-solid fa-tower-observation"></i>
                            {{ territory.activeZone.status === 'active' ? 'منطقة نشطة الآن' : 'منطقة مستقرة' }}
                        </div>
                        <div class="terr-active-meta">
                            <span><i class="fa-solid fa-ruler-combined"></i> {{ territory.activeZone.radius }}m</span>
                            <span><i class="fa-solid fa-clock"></i> {{ territory.activeZone.capture_seconds }}ث</span>
                            <span v-if="territory.activeZone.owner_label" :style="{color: territory.activeZone.owner_color}">
                                <i class="fa-solid fa-flag"></i> {{ territory.activeZone.owner_label }}
                            </span>
                        </div>
                        <!-- معلومات المستحِل الحالي -->
                        <div class="terr-capturer-info" v-if="territory.activeZone.capturer_name">
                            <i class="fa-solid fa-person-running"></i>
                            <span>يستحل الآن: <b>{{ territory.activeZone.capturer_name }}</b></span>
                            <span v-if="territory.activeZone.capturer_gang_id" class="terr-capturer-gang">
                                ({{ territory.activeZone.capturer_gang_id }})
                            </span>
                        </div>
                        <!-- زر سحب الاستحلال من المسؤول -->
                        <button class="terr-admin-cancel-btn"
                                v-if="territory.activeZone.capturer_name"
                                @click="adminCancelTerritoryCapture(territory.activeZone.id)">
                            <i class="fa-solid fa-ban"></i> سحب الاستحلال من العصابة
                        </button>
                    </div>

                    <div class="section-label"><i class="fa-solid fa-map-location-dot"></i> المناطق المحتلة</div>
                    <div class="terr-zone-list">
                        <div class="terr-zone-row" v-for="z in territory.zones" :key="z.id">
                            <!-- حالة التعديل المباشر للاسم -->
                            <div class="terr-zone-rename-row" v-if="territory.renameZone.id === z.id">
                                <input class="terr-rename-input" v-model="territory.renameZone.name"
                                       @keyup.enter="adminConfirmRenameZone(z.id)"
                                       @keyup.esc="adminCancelRenameZone"
                                       maxlength="40" placeholder="اسم المنطقة…">
                                <button class="terr-rename-confirm-btn" @click="adminConfirmRenameZone(z.id)">
                                    <i class="fa-solid fa-check"></i>
                                </button>
                                <button class="terr-rename-cancel-btn" @click="adminCancelRenameZone">
                                    <i class="fa-solid fa-times"></i>
                                </button>
                            </div>
                            <!-- العرض العادي -->
                            <template v-else>
                                <div class="terr-zone-title">
                                    {{ z.label }}
                                    <button class="terr-rename-edit-btn" @click="adminStartRenameZone(z.id, z.label)" title="تعديل الاسم">
                                        <i class="fa-solid fa-pen"></i>
                                    </button>
                                    <button class="terr-zone-delete-btn" @click="adminDeleteTerritoryZone(z.id, z.label)" title="حذف المنطقة">
                                        <i class="fa-solid fa-trash"></i>
                                    </button>
                                </div>
                                <div class="terr-zone-badges">
                                    <span class="terr-badge active" v-if="z.status === 'active'">
                                        <i class="fa-solid fa-fire"></i> قيد الاستحلال
                                    </span>
                                    <button class="terr-admin-cancel-btn" v-if="z.status === 'active' && z.capturer_name" @click="adminCancelTerritoryCapture(z.id)">
                                        <i class="fa-solid fa-ban"></i> سحب الاستحلال الجاري
                                    </button>
                                    <button class="terr-zone-cancel-full-btn" v-if="z.status === 'active'" @click="adminCancelTerritoryBattle(z.id)">
                                        <i class="fa-solid fa-ban"></i> إلغاء كامل عملية الاستحلال
                                    </button>
                                    <span class="terr-badge owner" v-else-if="z.owner_label" :style="{borderColor: z.owner_color, color: z.owner_color}">
                                        <i class="fa-solid fa-flag"></i> {{ z.owner_label }}
                                    </span>
                                    <span class="terr-badge none" v-else>
                                        <i class="fa-solid fa-ban"></i> بدون مالك
                                    </span>
                                </div>
                            </template>
                        </div>
                        <div class="empty-placeholder" v-if="territory.zones.length === 0">
                            <i class="fa-solid fa-map"></i>
                            <span>لا توجد مناطق مسجلة بعد</span>
                        </div>
                    </div>
                    </div>
                </div>

                <!-- ════ المتاجر والخزائن القذرة ════ -->
                <div v-if="adminPanel.activeCategory === 'admin-shops'" class="cat-admin-shops">

                    <!-- جاري التحميل -->
                    <div v-if="adminPanel.shops.loading" class="ash-loading">
                        <i class="fa-solid fa-spinner fa-spin"></i>
                        <span>جاري جلب بيانات المتاجر...</span>
                    </div>

                    <!-- قائمة العصابات -->
                    <div v-else class="admin-shops-list">
                        <div class="admin-shop-card"
                             v-for="(s, idx) in adminPanel.shops.list" :key="s.gang_id"
                             :style="{'--gc': s.color || '#4d7fff'}">

                            <!-- رأس البطاقة: شعار + اسم + شارات + أزرار سريعة -->
                            <div class="ash-header">
                                <div class="ash-logo-wrap">
                                    <img v-if="s.logo" :src="s.logo" class="ash-logo">
                                    <i v-else class="fa-solid fa-shield-halved" :style="{color:s.color,fontSize:'1.3rem'}"></i>
                                </div>
                                <div class="ash-title">
                                    <span class="ash-gang-name" :style="{color:s.color}">{{ s.label }}</span>
                                    <div class="ash-badges-row">
                                        <span v-if="!s.shop_owned"  class="ash-badge ash-badge-none"><i class="fa-solid fa-store-slash"></i> لا يوجد متجر</span>
                                        <span v-else-if="s.shop_disabled" class="ash-badge ash-badge-closed"><i class="fa-solid fa-lock"></i> مغلق مؤقتاً</span>
                                        <span v-else class="ash-badge ash-badge-open"><i class="fa-solid fa-circle-check"></i> مفتوح</span>
                                        <span class="ash-badge ash-badge-dirty">
                                            <i class="fa-solid fa-sack-dollar"></i>
                                            {{ (s.dirty_balance||0).toLocaleString() }}$
                                        </span>
                                    </div>
                                </div>
                                <!-- أزرار التحكم السريع -->
                                <div class="ash-quick-actions" v-if="s.shop_owned">
                                    <button :class="['ash-icon-btn', s.shop_disabled ? 'success' : 'warn']"
                                            :title="s.shop_disabled ? 'فتح المتجر' : 'إغلاق مؤقت'"
                                            @click="adminToggleShop(s.gang_id)">
                                        <i :class="s.shop_disabled ? 'fa-solid fa-lock-open' : 'fa-solid fa-lock'"></i>
                                    </button>
                                    <button class="ash-icon-btn danger" title="حذف نهائي"
                                            @click="adminDeleteShop(s.gang_id)">
                                        <i class="fa-solid fa-trash"></i>
                                    </button>
                                </div>
                            </div>

                            <!-- مخزون الأسلحة -->
                            <div v-if="s.shop_owned && s.items && s.items.length" class="ash-items">
                                <div class="ash-items-title"><i class="fa-solid fa-boxes-stacked"></i> مخزون الأسلحة</div>
                                <div class="ash-item-row" v-for="it in s.items" :key="it.weapon">
                                    <span class="ash-item-dot" :style="{background: s.color}"></span>
                                    <span class="ash-item-label">{{ it.label }}</span>
                                    <span class="ash-item-stock"><i class="fa-solid fa-box"></i> {{ it.stock }}</span>
                                    <span class="ash-item-price">{{ it.price.toLocaleString() }}$</span>
                                </div>
                            </div>
                            <div v-else-if="s.shop_owned" class="ash-empty-inv">
                                <i class="fa-solid fa-box-open"></i> المخزون فارغ
                            </div>

                        </div>
                    </div>
                </div>

                <!-- ════ حساب الكنز المفقود ════ -->
                <div v-if="adminPanel.activeCategory === 'admin-treasure'" class="cat-admin-treasure">

                    <!-- رأس الصفحة -->
                    <div class="tre-header">
                        <div class="tre-header-icon"><i class="fa-solid fa-skull"></i></div>
                        <div class="tre-header-texts">
                            <div class="tre-header-title">حساب الكنز المفقود</div>
                            <div class="tre-header-sub">عرض وإدارة رصيد الكنز لكل عصابة</div>
                        </div>
                        <button class="tre-point-btn" @click="adminSetTreasureDepositPoint">
                            <i class="fa-solid fa-location-dot"></i>
                            {{ adminPanel.treasure.hasDepositPoint ? 'تحديث نقطة الإيداع' : 'تحديد نقطة الإيداع' }}
                        </button>
                        <button class="tre-refresh-btn" @click="adminLoadTreasure"
                                :class="{spinning: adminPanel.treasure.loading}">
                            <i class="fa-solid fa-rotate"></i>
                        </button>
                    </div>

                    <div class="tre-point-meta">
                        <i class="fa-solid fa-location-crosshairs"></i>
                        <span>نقطة الإيداع: {{ adminPanel.treasure.depositPointLbl }}</span>
                    </div>

                    <!-- جاري التحميل -->
                    <div v-if="adminPanel.treasure.loading && !adminPanel.treasure.list.length" class="tre-loading">
                        <i class="fa-solid fa-spinner fa-spin"></i>
                        <span>جاري جلب البيانات...</span>
                    </div>

                    <!-- بطاقات العصابات -->
                    <div v-else class="tre-cards">
                        <div class="tre-card" v-for="g in adminPanel.treasure.list" :key="g.gang_id"
                             :style="{'--gc': g.color || '#4d7fff'}">

                            <!-- رأس البطاقة -->
                            <div class="tre-card-head">
                                <div class="tre-card-logo-wrap">
                                    <img v-if="g.logo" :src="g.logo" class="tre-card-logo">
                                    <i v-else class="fa-solid fa-shield-halved" :style="{color:g.color,fontSize:'1.4rem'}"></i>
                                </div>
                                <div class="tre-card-info">
                                    <div class="tre-card-name" :style="{color:g.color}">{{ g.label }}</div>
                                    <div class="tre-card-count">
                                        <i class="fa-solid fa-skull" style="color:#e74c3c;margin-left:4px;font-size:.85rem"></i>
                                        <span class="tre-count-num" :style="{color:g.color}">{{ g.count }}</span>
                                        <span class="tre-count-label">كنز</span>
                                    </div>
                                </div>
                                <button class="tre-reset-btn" title="تصفير"
                                        @click.stop.prevent="adminTreasureReset(g.gang_id)"
                                        :disabled="g.count === 0 || g._busy === true">
                                    <i :class="g._busy ? 'fa-solid fa-spinner fa-spin' : 'fa-solid fa-trash-can'"></i>
                                    تصفير
                                </button>
                            </div>

                            <!-- شريط الكنز -->
                            <div class="tre-bar-wrap">
                                <div class="tre-bar-fill" :style="{width: Math.min(g.count * 10, 100) + '%', background: g.color}"></div>
                            </div>

                            <!-- خصم عدد معين -->
                            <div class="tre-deduct-row">
                                <input class="tre-input" type="number" min="1" :max="g.count"
                                       v-model.number="g._deduct"
                                       placeholder="أدخل عدد الخصم...">
                                <button class="tre-deduct-btn"
                                        :disabled="g._busy === true || !g._deduct || g._deduct <= 0 || g._deduct > g.count"
                                        @click.stop.prevent="adminTreasureDeduct(g.gang_id, g._deduct)">
                                    <i :class="g._busy ? 'fa-solid fa-spinner fa-spin' : 'fa-solid fa-minus'"></i>
                                    خصم
                                </button>
                            </div>

                        </div>

                        <div class="tre-empty" v-if="!adminPanel.treasure.list.length">
                            <i class="fa-solid fa-box-open"></i>
                            <span>لا توجد بيانات</span>
                        </div>
                    </div>

                </div><!-- /cat-admin-treasure -->

            </div><!-- /main-content -->
        </div><!-- /body-layout -->
    </div><!-- /adminContainer -->
    </transition>


    <!-- ══════════ SHOP E-KEY HINT ══════════ -->
    <transition name="hint-slide">
        <div class="shop-hint-bar" v-if="shopHint && !shopBuy.show">
            <div class="shop-hint-key">E</div>
            <i class="fa-solid fa-gun shop-hint-icon"></i>
            <span class="shop-hint-text">اضغط للتسوق من متجر الأسلحة</span>
        </div>
    </transition>

    <!-- ══════════ SHOP BUY MODAL ══════════ -->
    <transition name="sbc-fade">
        <div class="sbc-overlay" v-if="shopBuy.show" @click.self="closeShopBuy">
            <div class="sbc-box"
                 :style="{
                     '--gc':        shopBuy.gangColor || '#4d7fff',
                     '--gc-dim':    (shopBuy.gangColor || '#4d7fff') + '22',
                     '--gc-mid':    (shopBuy.gangColor || '#4d7fff') + '55',
                     borderColor:  (shopBuy.gangColor || '#4d7fff') + '55'
                 }">

                <!-- ───── HEADER ───── -->
                <div class="sbc-header"
                     :style="{background: 'linear-gradient(160deg,'+shopBuy.gangColor+'28 0%,'+shopBuy.gangColor+'08 100%)'}">

                    <div class="sbc-header-glow"
                         :style="{background: 'radial-gradient(ellipse at 30% 50%, '+shopBuy.gangColor+'18, transparent 70%)'}"></div>

                    <!-- لوغو -->
                    <div class="sbc-logo-wrap"
                         :style="{'box-shadow': '0 0 24px '+shopBuy.gangColor+'44', 'border-color': shopBuy.gangColor+'66'}">
                        <img v-if="shopBuy.gangLogo" :src="shopBuy.gangLogo" class="sbc-logo">
                        <i v-else class="fa-solid fa-shield-halved" :style="{color: shopBuy.gangColor, fontSize: '2rem'}"></i>
                    </div>

                    <!-- نص -->
                    <div class="sbc-header-text">
                        <div class="sbc-gang-name" :style="{color: shopBuy.gangColor}">{{ shopBuy.gangName }}</div>
                        <div class="sbc-gang-sub">
                            <i class="fa-solid fa-gun"></i> متجر الأسلحة
                        </div>
                        <div class="sbc-avail-badge" :style="{color: shopBuy.gangColor, 'border-color': shopBuy.gangColor+'44', background: shopBuy.gangColor+'12'}">
                            <i class="fa-solid fa-boxes-stacked"></i>
                            {{ shopBuy.items.filter(i => i.stock > 0).length }}/{{ shopBuy.items.length }} صنف متاح
                        </div>
                    </div>

                    <!-- قفل -->
                    <button class="sbc-close-btn" @click="closeShopBuy">
                        <i class="fa-solid fa-xmark"></i>
                    </button>

                    <!-- خط سفلي -->
                    <div class="sbc-header-divider"
                         :style="{background: 'linear-gradient(90deg, transparent, '+shopBuy.gangColor+', transparent)'}"></div>
                </div>

                <!-- ───── ITEMS ───── -->
                <div class="sbc-list">

                    <!-- فارغ -->
                    <div class="sbc-empty" v-if="shopBuy.items.length === 0">
                        <i class="fa-solid fa-box-open"></i>
                        <span>المتجر فارغ حالياً</span>
                    </div>

                    <div v-for="item in shopBuy.items"
                         :key="item.weapon"
                         class="sbc-card"
                         :class="{disabled: item.stock <= 0}"
                         :style="item.stock > 0 ? {'border-color': shopBuy.gangColor+'30'} : {}">

                        <!-- أيقونة السلاح -->
                        <div class="sbc-card-icon"
                             :style="item.stock > 0
                                 ? {background: shopBuy.gangColor+'18', 'border-color': shopBuy.gangColor+'44', color: shopBuy.gangColor}
                                 : {}">
                            <i :class="
                                item.weapon && item.weapon.includes('KNIFE')  ? 'fa-solid fa-knife' :
                                item.weapon && item.weapon.includes('PISTOL') ? 'fa-solid fa-gun' :
                                item.weapon && item.weapon.includes('SMG')    ? 'fa-solid fa-gun' :
                                item.weapon && item.weapon.includes('RIFLE')  ? 'fa-solid fa-gun' :
                                item.weapon && item.weapon.includes('SHOTGUN')? 'fa-solid fa-gun' :
                                item.weapon && item.weapon.includes('SNIPER') ? 'fa-solid fa-crosshairs' :
                                item.weapon && item.weapon.includes('RPG')    ? 'fa-solid fa-rocket' :
                                item.weapon && item.weapon.includes('GRENADE')? 'fa-solid fa-bomb' :
                                'fa-solid fa-gun'"></i>
                        </div>

                        <!-- معلومات السلاح -->
                        <div class="sbc-card-body">
                            <div class="sbc-card-name">{{ item.label }}</div>
                            <div class="sbc-card-tags">
                                <span class="sbc-tag ammo" v-if="item.ammo > 0">
                                    <i class="fa-solid fa-circle-dot"></i> {{ item.ammo }} طلقة
                                </span>
                                <span class="sbc-tag no-ammo" v-else>
                                    <i class="fa-solid fa-slash"></i> بدون ذخيرة
                                </span>
                                <span :class="['sbc-tag stock', item.stock <= 0 ? 'empty' : item.stock <= 5 ? 'low' : 'ok']">
                                    <i :class="item.stock > 0 ? 'fa-solid fa-layer-group' : 'fa-solid fa-ban'"></i>
                                    {{ item.stock > 0 ? item.stock + ' متبقي' : 'نفذ' }}
                                </span>
                            </div>
                        </div>

                        <!-- السعر + زر الشراء -->
                        <div class="sbc-card-action">
                            <div class="sbc-card-price" :style="item.stock > 0 ? {color: shopBuy.gangColor} : {}">
                                {{ item.price.toLocaleString() }}$
                            </div>
                            <button class="sbc-buy-btn"
                                    @click="buyWeapon(item)"
                                    :disabled="item.stock <= 0"
                                    :style="item.stock > 0
                                        ? {background: 'linear-gradient(135deg,'+shopBuy.gangColor+' 0%,'+shopBuy.gangColor+'aa 100%)',
                                           'box-shadow': '0 4px 18px '+shopBuy.gangColor+'44'}
                                        : {}">
                                <i class="fa-solid fa-cart-plus"></i>
                                شراء
                            </button>
                        </div>

                    </div>
                </div>

                <!-- ───── FOOTER ───── -->
                <div class="sbc-footer">
                    <i class="fa-solid fa-hand-pointer"></i>
                    <span>اضغط خارج النافذة للإغلاق</span>
                </div>

            </div>
        </div>
    </transition>

    <!-- ══════════ TERRITORY E-KEY HINT ══════════ -->
    <transition name="territory-hint-slide-right">
        <div class="territory-hint-box" v-if="territoryHint">
            <div class="territory-hint-key-badge">E</div>
            <div class="territory-hint-label">ابدأ الاستحلال</div>
            <i class="fa-solid fa-crosshairs territory-hint-icon"></i>
        </div>
    </transition>

    <!-- ══════════ SPECIAL DEPOSIT HINT ══════════ -->
    <transition name="territory-hint-slide-right">
        <div class="territory-hint-box special-deposit-hint" v-if="specialDepositHint">
            <div class="territory-hint-key-badge">E</div>
            <div class="territory-hint-label">أودع الكنز المفقود</div>
            <i class="fa-solid fa-gem territory-hint-icon" style="color:#FFD700"></i>
        </div>
    </transition>

    <!-- ══════════ SPECIAL ITEM WON MODAL ══════════ -->
    <transition name="special-item-pop">
        <div class="special-item-modal" v-if="specialItemModal.show">
            <div class="sim-glow"></div>
            <div class="sim-icon">{{ specialItemModal.icon }}</div>
            <div class="sim-title" v-if="!specialItemModal.looted">🏆 حصلت على الكنز المفقود!</div>
            <div class="sim-title" v-else>⚔️ سلبت الكنز المفقود!</div>
            <div class="sim-label">{{ specialItemModal.label }}</div>
            <div class="sim-sub">توجّه إلى النقطة الذهبية على الخريطة وأودعه بالضغط على E</div>
        </div>
    </transition>

    <!-- ══════════ TERRITORY CAPTURE OVERLAY ══════════ -->
    <transition name="territory-slide">
        <div class="terr-capture-overlay" v-if="territory.captureActive && !adminPanel.show">
            <div class="terr-capture-panel">

                <!-- Header -->
                <div class="terr-cap-header">
                    <div class="terr-cap-icon-wrap">
                        <i class="fa-solid fa-crosshairs terr-cap-icon pulsing-red"></i>
                    </div>
                    <div class="terr-cap-title">جاري استحلال المنطقة</div>
                </div>

                <!-- Timer + progress -->
                <div class="terr-cap-timer-row">
                    <i class="fa-regular fa-clock"></i>
                    <span class="terr-cap-time-val">{{ captureTimeLeftFmt }}</span>
                    <small>متبقي</small>
                </div>

                <div class="terr-cap-progress-section">
                    <div class="terr-cap-bar">
                        <div class="terr-cap-bar-fill" :style="{ width: captureProgress + '%' }">
                            <div class="terr-cap-bar-dot"></div>
                        </div>
                    </div>
                    <span class="terr-cap-pct">{{ Math.round(captureProgress) }}%</span>
                </div>

                <!-- Warning -->
                <div class="terr-cap-warning">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                    لا تموت ولا تخرج من النطاق
                </div>

            </div>
        </div>
    </transition>

    <!-- ══════════ LAUNDRY E-KEY HINT ══════════ -->
    <transition name="hint-slide-right">
        <div class="laundry-hint-box" v-if="laundryHint && !laundry.active && !laundry.done"
             style="display:flex;flex-direction:row;align-items:center;gap:10px;">
            <div class="laundry-hint-key-badge">E</div>
            <div class="laundry-hint-label">اضغط لبدأ الغسيل</div>
            <i class="fa-solid fa-money-bill-wave laundry-hint-icon"></i>
        </div>
    </transition>

    <!-- ══════════ LAUNDRY OVERLAY ══════════ -->
    <transition name="laundry-slide">
        <div class="laundry-overlay" v-if="laundry.active || laundry.done">
            <div class="laundry-panel" :class="{ 'is-done': laundry.done }">

                <!-- Header -->
                <div class="laundry-header"
                     style="display:flex;flex-direction:column;align-items:center;justify-content:center;gap:6px;margin-bottom:18px;width:100%;">
                    <div class="laundry-icon-wrap">
                        <i class="fa-solid fa-money-bill-wave laundry-icon" :class="{ pulsing: laundry.active }"></i>
                    </div>
                    <div class="laundry-title">
                        <span v-if="laundry.active">جاري غسيل الأموال</span>
                        <span v-else><i class="fa-solid fa-circle-check"></i> اكتمل الغسيل</span>
                    </div>
                </div>

                <!-- Active state -->
                <template v-if="laundry.active">
                    <!-- Amounts -->
                    <div class="laundry-amounts">
                        <div class="laundry-amount dirty">
                            <i class="fa-solid fa-money-bill-transfer"></i>
                            <span>{{ laundryDirtyFormatted }}</span>
                            <small>قذرة</small>
                        </div>
                        <div class="laundry-arrow-anim">
                            <i class="fa-solid fa-arrow-left"></i>
                        </div>
                        <div class="laundry-amount clean">
                            <i class="fa-solid fa-sack-dollar"></i>
                            <span>{{ laundryCleanFormatted }}</span>
                            <small>نظيفة</small>
                        </div>
                    </div>

                    <!-- Timer -->
                    <div class="laundry-timer">
                        <i class="fa-regular fa-clock"></i>
                        <span class="laundry-time-val">{{ laundryTimeLeft }}</span>
                        <small>متبقي</small>
                    </div>

                    <!-- Progress bar (below timer) -->
                    <div class="laundry-progress-section">
                        <div class="laundry-bar">
                            <div class="laundry-bar-fill" :style="{ width: laundryProgress + '%' }">
                                <div class="laundry-bar-dot"></div>
                            </div>
                        </div>
                        <span class="laundry-pct">{{ Math.round(laundryProgress) }}%</span>
                    </div>

                    <!-- Cancel button -->
                    <button class="laundry-cancel-btn" @click="cancelLaundry">
                        <i class="fa-solid fa-xmark"></i> إلغاء الغسيل
                    </button>
                </template>

                <!-- Done state -->
                <div class="laundry-done-section" v-if="laundry.done">
                    <div class="laundry-done-amount">
                        <i class="fa-solid fa-circle-check"></i>
                        +{{ laundryCleanFormatted }}
                    </div>
                    <div class="laundry-done-sub">ريال نظيف تم تحويله</div>
                </div>

            </div>
        </div>
    </transition>
</div>
`;

const RUNTIME_STYLE_CSS = `
/* 
       BASE
     */
    [v-cloak]{display:none}
    *{box-sizing:border-box;font-family:'Tajawal',sans-serif;user-select:none;-webkit-user-select:none}
    body{margin:0;overflow:hidden;background:transparent}
    #app{width:100vw;height:100vh;display:flex;justify-content:center;align-items:center;background:transparent}
    
    /* 
       GANG SELECTOR
     */
    .selector-overlay{
        position:fixed;inset:0;
        display:flex;align-items:center;justify-content:center;
        background:radial-gradient(ellipse at center,rgba(10,10,40,.55) 0%,transparent 70%);
    }
    .selector-box{
        background:
            linear-gradient(rgba(var(--p-rgb),.025) 1px,transparent 1px),
            linear-gradient(90deg,rgba(var(--p-rgb),.025) 1px,transparent 1px),
            linear-gradient(158deg,var(--bg-grad1));
        background-size:28px 28px,28px 28px,auto;
        border:1px solid var(--ba);
        border-radius:var(--r4);
        padding:34px 38px;
        min-width:390px;
        box-shadow:var(--sh),0 0 90px rgba(var(--p-rgb),.09);
        position:relative;
        overflow:hidden;
    }
    /* Top color slash line */
    .selector-box::before{
        content:"";position:absolute;top:0;left:0;right:0;height:2px;
        background:var(--p-line);
    }
    .selector-title{
        color:var(--t0);
        font-size:17px;font-weight:900;
        text-align:center;margin-bottom:26px;
        text-transform:uppercase;letter-spacing:2px;
    }
    .selector-title::after{
        content:"";display:block;width:44px;height:2px;
        background:var(--p-ac-grad);
        margin:9px auto 0;border-radius:2px;
        box-shadow:0 0 10px rgba(var(--p-rgb),.5);
    }
    .selector-grid{
        display:grid;
        grid-template-columns:repeat(auto-fill,minmax(140px,1fr));
        gap:13px;
    }
    .selector-card{
        background:rgba(var(--white-rgb),.028);
        border:1px solid var(--b);
        border-radius:var(--r2);
        padding:22px 14px;
        display:flex;flex-direction:column;align-items:center;gap:12px;
        cursor:pointer;transition:var(--ease);
        position:relative;overflow:hidden;
    }
    .selector-card::after{
        content:"";position:absolute;bottom:0;left:0;right:0;height:2px;
        background:var(--p-ac-grad);
        transform:scaleX(0);transition:transform var(--ease);
    }
    .selector-card:hover{
        background:rgba(var(--p-rgb),.08);
        border-color:var(--ba);
        transform:translateY(-5px);
        box-shadow:0 18px 44px rgba(var(--black-rgb),.7),0 0 22px rgba(var(--p-rgb),.13);
    }
    .selector-card:hover::after{transform:scaleX(1)}
    .selector-logo{
        width:62px;height:62px;border-radius:50%;
        object-fit:cover;
        border:2px solid transparent;
        background:linear-gradient(var(--bg0),var(--bg0)) padding-box,
                   var(--p-ac-grad) border-box;
        box-shadow:0 0 22px rgba(var(--p-rgb),.22);
        transition:var(--ease);
    }
    .selector-card:hover .selector-logo{box-shadow:0 0 36px rgba(var(--p-rgb),.4)}
    .selector-name{font-size:13.5px;font-weight:800;text-align:center;color:var(--t1)}
    
    /* 
       MAIN CONTAINER
     */
    #mainContainer{
        width:1140px;height:660px;
        display:flex;flex-direction:column;
        border-radius:var(--r3);
        box-shadow:var(--sh),0 0 0 1px rgba(var(--p-rgb),.1);
        overflow:hidden;
        position:fixed;
        top:50%;left:50%;
        transform:translate(-50%,-50%);
        z-index:100;
    }
    
    /* 
       HEADER
     */
    .header{
        width:100%;height:112px;
        background:linear-gradient(115deg,var(--bg-head-stops));
        border-bottom:1px solid var(--ba);
        display:flex;align-items:center;gap:18px;
        padding:0 24px;
        position:relative;overflow:hidden;flex-shrink:0;
        border-radius:var(--r3) var(--r3) 0 0;
    }
    /* Bottom accent line */
    .header::after{
        content:"";position:absolute;bottom:0;left:0;right:0;height:1px;
        background:var(--p-line);
        opacity:.75;
    }
    /* Diagonal slash */
    .header::before{
        content:"";position:absolute;
        top:-50px;right:100px;
        width:1px;height:200px;
        background:linear-gradient(180deg,transparent,rgba(var(--p-rgb),.22),transparent);
        transform:rotate(-18deg);
        pointer-events:none;
    }
    .header-glow-orb{
        position:absolute;top:-28px;right:7%;
        width:280px;height:190px;
        background:radial-gradient(ellipse,rgba(var(--p-rgb),.17) 0%,transparent 70%);
        pointer-events:none;
    }
    .header-right{flex-shrink:0}
    .header-logo{
        width:76px;height:76px;border-radius:16px;
        object-fit:cover;
        border:2px solid transparent;
        background:linear-gradient(var(--bg-head),var(--bg-head)) padding-box,
                   var(--p-ac-grad) border-box;
        box-shadow:0 0 32px rgba(var(--p-rgb),.28),0 4px 16px rgba(var(--black-rgb),.6);
        transition:var(--ease-b);
    }
    .header-logo:hover{
        box-shadow:0 0 52px rgba(var(--p-rgb),.55),0 4px 20px rgba(var(--black-rgb),.6);
        transform:scale(1.05);
    }
    .header-text{display:flex;flex-direction:column;gap:5px;position:relative;z-index:1}
    .header-gang-name{
        margin:0;
        font-size:24px;font-weight:900;letter-spacing:-.3px;
        background:linear-gradient(135deg,var(--p-light),var(--p),var(--ac-light));
        -webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;
        filter:drop-shadow(0 0 16px rgba(var(--p-rgb),.35));
    }
    .header-sub{
        color:var(--t3);font-size:9.5px;font-weight:800;
        text-transform:uppercase;letter-spacing:2.5px;
    }
    .close-btn{
        position:absolute;left:20px;top:50%;transform:translateY(-50%);
        background:var(--d-dim);border:1px solid rgba(var(--d-rgb),.3);
        color:var(--danger);width:38px;height:38px;border-radius:10px;
        cursor:pointer;transition:var(--ease);
        display:flex;align-items:center;justify-content:center;font-size:15px;
        z-index:2;
    }
    .close-btn:hover{
        background:var(--danger);border-color:var(--danger);color:#fff;
        transform:translateY(-50%) rotate(90deg);
        box-shadow:var(--sh-d);
    }
    
    /* 
       BODY LAYOUT
     */
    .body-layout{
        display:grid;grid-template-columns:205px 1fr;
        flex:1;overflow:hidden;
        background:var(--bg1);
        border-radius:0 0 var(--r3) var(--r3);
        border:1px solid var(--b);border-top:none;
    }
    
    /* 
       SIDEBAR
     */
    .sidebar{
        background:var(--bg-sb);
        padding:18px 10px;
        border-left:1px solid var(--b);
        display:flex;flex-direction:column;
        position:relative;
    }
    /* Right edge shimmer */
    .sidebar::after{
        content:"";position:absolute;top:0;bottom:0;right:-1px;width:1px;
        background:linear-gradient(180deg,
            transparent 5%,
            rgba(var(--p-rgb),.18) 35%,
            rgba(var(--p-rgb),.18) 65%,
            transparent 95%);
        pointer-events:none;
    }
    .categories-label{
        color:var(--t3);font-size:8.5px;font-weight:900;text-transform:uppercase;
        letter-spacing:2.5px;margin-bottom:14px;padding-right:6px;
    }
    .sidebar-list{display:flex;flex-direction:column;gap:4px}
    .sidebar-item{
        padding:11px 12px;border-radius:var(--r0);cursor:pointer;
        color:var(--t2);background:transparent;
        transition:var(--ease);
        display:flex;align-items:center;gap:11px;
        border:1px solid transparent;
        position:relative;overflow:hidden;
    }
    .sidebar-item i{font-size:14px;width:17px;text-align:center;flex-shrink:0;transition:var(--ease)}
    .sidebar-item span{font-size:12.5px;font-weight:700}
    .sidebar-item:hover{
        background:rgba(var(--p-rgb),.055);
        color:var(--t1);
        border-color:rgba(var(--p-rgb),.14);
    }
    .sidebar-item.active{
        background:linear-gradient(105deg,rgba(var(--p-dark-rgb),.65),rgba(var(--p-rgb),.17));
        color:#fff;
        border-color:rgba(var(--p-rgb),.38);
        box-shadow:inset 0 1px 0 rgba(var(--white-rgb),.04);
    }
    .sidebar-item.active i{
        color:var(--p);
        filter:drop-shadow(0 0 10px rgba(var(--p-rgb),.8));
    }
    /* Active right accent bar */
    .sidebar-item.active::before{
        content:"";position:absolute;right:0;top:12%;bottom:12%;
        width:3px;
        background:linear-gradient(180deg,var(--p),var(--ac));
        border-radius:2px;
        box-shadow:0 0 14px rgba(var(--p-rgb),.9);
    }
    /* Hover sweep */
    .sidebar-item:not(.active):hover::before{
        content:"";position:absolute;inset:0;
        background:linear-gradient(90deg,transparent,rgba(var(--p-rgb),.04),transparent);
        pointer-events:none;
        border:none;
    }
    
    /* 
       MAIN CONTENT
     */
    .main-content{
        background:var(--bg2);
        padding:18px 20px 16px;
        overflow-y:auto;overflow-x:hidden;
        display:flex;flex-direction:column;gap:15px;
        scrollbar-width:thin;
        scrollbar-color:rgba(var(--p-rgb),.25) transparent;
    }
    .main-content::-webkit-scrollbar{width:3px}
    .main-content::-webkit-scrollbar-thumb{background:rgba(var(--p-rgb),.3);border-radius:3px}
    
    /* 
       SHARED  SECTION LABEL
     */
    .section-label{
        color:var(--t3);font-size:8.5px;font-weight:900;
        text-transform:uppercase;letter-spacing:2px;
        margin-bottom:10px;
        display:flex;align-items:center;gap:7px;
    }
    .section-label i{font-size:10px;color:var(--p)}
    .section-label::after{
        content:"";flex:1;height:1px;
        background:linear-gradient(90deg,rgba(var(--p-rgb),.2),transparent);
        min-width:20px;
    }
    
    /* 
       SHARED  INPUTS
     */
    .gang-input{
        width:100%;padding:11px 14px;
        background:rgba(var(--white-rgb),.024);
        border:1px solid var(--b);border-radius:var(--r0);
        color:var(--t0);outline:none;
        font-size:13.5px;font-family:'Tajawal',sans-serif;
        transition:var(--ease);
    }
    .gang-input:focus,.gang-input:hover{
        border-color:var(--ba);
        background:rgba(var(--p-rgb),.042);
        box-shadow:0 0 0 3px rgba(var(--p-rgb),.09);
    }
    .gang-input::-webkit-inner-spin-button{-webkit-appearance:none}
    .gang-input::placeholder{color:var(--t3)}
    
    .gang-textarea{
        width:100%;min-height:82px;padding:11px 14px;resize:vertical;
        background:rgba(var(--white-rgb),.024);
        border:1px solid var(--b);border-radius:var(--r0);
        color:var(--t0);outline:none;
        font-size:13px;font-family:'Tajawal',sans-serif;
        transition:var(--ease);
    }
    .gang-textarea:focus{
        border-color:var(--ba);
        background:rgba(var(--p-rgb),.042);
        box-shadow:0 0 0 3px rgba(var(--p-rgb),.09);
    }
    .gang-textarea::placeholder{color:var(--t3)}
    .gang-textarea.sm{min-height:54px}
    
    /* 
       WARNING BANNER
     */
    .gang-warning-banner{
        display:flex;align-items:center;gap:11px;
        padding:12px 18px;border-radius:var(--r0);
        background:linear-gradient(135deg,rgba(var(--d-rgb),.13),rgba(var(--d-deep-rgb),.06));
        border:1px solid rgba(var(--d-rgb),.4);
        color:var(--danger);font-size:13px;font-weight:800;
        cursor:pointer;transition:var(--ease);
        animation:warnPulse 2.5s ease-in-out infinite;
    }
    .gang-warning-banner:hover{
        background:linear-gradient(135deg,rgba(var(--d-rgb),.21),rgba(var(--d-deep-rgb),.11));
        border-color:rgba(var(--d-rgb),.68);
        box-shadow:0 0 28px rgba(var(--d-rgb),.22);
        animation:none;
    }
    .gang-warning-banner i:first-child{
        font-size:15px;
        animation:warnIcon 1.5s ease infinite;
    }
    .wbn-arrow{font-size:11px;margin-right:auto;opacity:.6}
    @keyframes warnPulse{0%,100%{box-shadow:0 0 0 0 rgba(var(--d-rgb),0)}50%{box-shadow:0 0 16px rgba(var(--d-rgb),.24)}}
    @keyframes warnIcon{0%,100%{color:var(--danger)}50%{color:#ff8096}}
    
    /* 
       HOME  STATS ROW
     */
    .stats-row{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}
    .stat-card{
        /* Grid texture built into background */
        background:
            linear-gradient(rgba(var(--p-rgb),.045) 1px,transparent 1px),
            linear-gradient(90deg,rgba(var(--p-rgb),.045) 1px,transparent 1px),
            linear-gradient(155deg,rgba(24,16,7,.95),rgba(14,10,4,.95));
        background-size:22px 22px,22px 22px,auto;
        border:1px solid rgba(var(--p-rgb),.22);border-radius:var(--r1);
        padding:20px 16px;text-align:center;
        transition:var(--ease);position:relative;overflow:hidden;
    }
    /* Top accent line */
    .stat-card::before{
        content:"";position:absolute;top:0;left:0;right:0;height:2px;
        background:var(--p-line);opacity:.55;
    }
    /* Bottom glow */
    .stat-card::after{
        content:"";position:absolute;bottom:-24px;left:50%;transform:translateX(-50%);
        width:90px;height:50px;
        background:radial-gradient(ellipse,var(--p-glow-sm) 0%,transparent 70%);
        pointer-events:none;
    }
    .stat-card:hover{
        border-color:var(--ba);
        box-shadow:0 8px 30px rgba(var(--p-rgb),.16),0 0 0 1px rgba(var(--p-rgb),.2) inset;
        transform:translateY(-3px);
    }
    .stat-val{
        font-size:30px;font-weight:900;line-height:1;
        background:linear-gradient(135deg,var(--p-light),var(--p),var(--ac-light));
        -webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;
        filter:drop-shadow(0 0 12px rgba(var(--p-rgb),.45));
    }
    .stat-unit{font-size:15px;font-weight:800}
    .stat-lbl{
        font-size:9px;font-weight:800;color:rgba(var(--p-rgb),.72);
        margin-top:7px;text-transform:uppercase;letter-spacing:1.2px;
    }
    
    /* 
       HOME  TOP 5
     */
    .top5-box{
        background:var(--card);border:1px solid var(--b);border-radius:var(--r1);
        padding:14px 16px;position:relative;overflow:hidden;
    }
    .top5-box::before{
        content:"";position:absolute;top:0;left:0;right:0;height:1px;
        background:var(--p-line);opacity:.3;
    }
    .top5-list{display:flex;flex-direction:column;gap:5px;margin-top:2px}
    .top5-row{
        display:flex;align-items:center;gap:10px;
        padding:8px 12px;border-radius:var(--r0);
        background:rgba(var(--white-rgb),.018);border:1px solid var(--b);
        transition:var(--ease);
    }
    .top5-row:hover{border-color:var(--ba);background:rgba(var(--p-rgb),.055)}
    .top5-rank{font-size:11px;font-weight:900;width:28px;text-align:center;flex-shrink:0}
    .rank-1{color:#ffd700;text-shadow:0 0 14px rgba(255,215,0,.65)}
    .rank-2{color:#c8d4e4;text-shadow:0 0 8px rgba(200,212,228,.35)}
    .rank-3{color:#cd7f32;text-shadow:0 0 8px rgba(205,127,50,.35)}
    .rank-4,.rank-5{color:var(--t3)}
    .top5-name{flex:1;color:var(--t1);font-size:13px;font-weight:700}
    .top5-time{color:var(--p);font-size:11.5px;font-weight:800;letter-spacing:.5px}
    
    /* 
       HOME  TABS
     */
    .members-tabs{display:flex;gap:6px}
    .tab-btn{
        padding:8px 18px;border-radius:var(--r0);
        background:var(--card);border:1px solid var(--b);
        color:var(--t2);font-size:12px;font-weight:700;
        font-family:'Tajawal',sans-serif;cursor:pointer;transition:var(--ease);
    }
    .tab-btn:hover{background:var(--card-h);color:var(--t1);border-color:var(--ba)}
    .tab-btn.active{
        background:var(--p-grad);color:#fff;
        border-color:rgba(var(--p-rgb),.42);
        box-shadow:var(--sh-p);
    }
    
    /* 
       HOME  SEARCH
     */
    .search-box{
        background:rgba(var(--white-rgb),.02);border:1px solid var(--b);
        padding:9px 13px;border-radius:var(--r0);
        display:flex;align-items:center;gap:9px;transition:var(--ease);
    }
    .search-box:focus-within{border-color:var(--ba);box-shadow:0 0 0 3px rgba(var(--p-rgb),.08)}
    .search-box i{color:var(--t3);font-size:12px;flex-shrink:0}
    .search-box input{
        background:transparent;border:none;color:var(--t0);
        width:100%;outline:none;font-size:12.5px;font-family:'Tajawal',sans-serif;
    }
    .search-box input::placeholder{color:var(--t3)}
    
    /* 
       LOADING & EMPTY
     */
    .loading-row{
        display:flex;align-items:center;justify-content:center;
        gap:10px;color:var(--t3);font-size:13px;padding:32px 0;
    }
    .loading-row i{color:var(--p)}
    .empty-placeholder{
        display:flex;flex-direction:column;align-items:center;justify-content:center;
        gap:14px;padding:44px 0;color:var(--t3);font-size:13px;font-weight:600;
    }
    .empty-placeholder i{font-size:40px;opacity:.2;color:var(--p)}
    
    /* 
       MEMBER CARDS
     */
    .members-list{display:flex;flex-direction:column;gap:6px}
    .member-card{
        background:var(--card);
        border:1px solid var(--b);border-radius:var(--r0);
        overflow:hidden;transition:var(--ease);cursor:pointer;
        position:relative;
    }
    /* Left accent bar (right in RTL) */
    .member-card::after{
        content:"";position:absolute;right:0;top:0;bottom:0;width:2px;
        background:linear-gradient(180deg,var(--p),var(--ac));
        opacity:0;transition:var(--ease);
        box-shadow:0 0 8px var(--p);
    }
    .member-card:hover{border-color:rgba(var(--p-rgb),.26);background:rgba(var(--p-rgb),.04)}
    .member-card:hover::after{opacity:.5}
    .member-card.selected{
        border-color:rgba(var(--p-rgb),.44);
        background:rgba(var(--p-rgb),.055);
    }
    .member-card.selected::after{opacity:1}
    .mc-row{
        padding:9px 13px;
        display:grid;grid-template-columns:8px 40px 1fr 14px;
        column-gap:10px;align-items:center;
    }
    .member-avatar{
        width:40px;height:40px;border-radius:9px;
        object-fit:cover;
        border:1.5px solid rgba(var(--p-rgb),.24);
        transition:var(--ease);
    }
    .member-card:hover .member-avatar{
        border-color:rgba(var(--p-rgb),.5);
        box-shadow:0 0 14px rgba(var(--p-rgb),.2);
    }
    .member-info{display:flex;flex-direction:column;gap:4px;min-width:0}
    .member-name{
        color:var(--t0);font-size:13px;font-weight:700;
        white-space:nowrap;overflow:hidden;text-overflow:ellipsis;
    }
    .member-online-dot{
        width:7px;height:7px;border-radius:50%;
        background:var(--t3);flex-shrink:0;transition:var(--ease);
    }
    .member-online-dot.online{
        background:var(--success);
        animation:dotPulse 2s ease-in-out infinite;
    }
    @keyframes dotPulse{
        0%,100%{box-shadow:0 0 5px var(--success)}
        50%{box-shadow:0 0 14px var(--success),0 0 5px var(--success)}
    }
    .member-details{display:flex;gap:5px;flex-wrap:wrap;align-items:center}
    .mc-arrow{color:var(--t3);font-size:11px;transition:transform .2s ease;justify-self:center}
    .mc-arrow.rotated{transform:rotate(-90deg);color:var(--p)}
    
    /* Badges */
    .badge-id{
        background:rgba(var(--p-rgb),.11);color:var(--p-bright,#85b8ff);
        border:1px solid rgba(var(--p-rgb),.22);
        font-size:9.5px;font-weight:800;padding:1px 7px;border-radius:5px;
    }
    .badge-rank{
        background:rgba(var(--white-rgb),.04);color:var(--t2);
        border:1px solid var(--b);
        font-size:9.5px;font-weight:700;padding:1px 7px;border-radius:5px;
    }
    .badge-time{
        color:var(--t3);font-size:9.5px;font-weight:700;
        display:flex;align-items:center;gap:3px;
    }
    .badge-time i{font-size:9px}
    .badge-member{padding:2px 8px;border-radius:5px;font-size:10px;font-weight:800}
    .badge-member.yes{background:var(--s-dim);color:var(--success);border:1px solid rgba(var(--s-rgb),.25)}
    .badge-member.no{background:var(--d-dim);color:var(--danger);border:1px solid rgba(var(--d-rgb),.25)}
    .badge-online-sm{background:rgba(var(--s-rgb),.1);color:var(--success);border:1px solid rgba(var(--s-rgb),.25);font-size:9.5px;font-weight:800;padding:1px 7px;border-radius:5px}
    .badge-warn-sm{background:rgba(var(--d-rgb),.1);color:var(--danger);border:1px solid rgba(var(--d-rgb),.25);font-size:9.5px;font-weight:800;padding:1px 7px;border-radius:5px}
    
    /* Action Row */
    .mc-actions-row{
        display:flex;gap:6px;padding:8px 12px 10px;
        border-top:1px solid rgba(var(--p-rgb),.1);
        flex-wrap:wrap;
        background:rgba(var(--p-rgb),.025);
    }
    .mc-action-btn{
        flex:1;min-width:68px;padding:8px 7px;border-radius:var(--r0);
        border:1px solid var(--b);background:var(--card);color:var(--t2);
        display:flex;align-items:center;justify-content:center;gap:5px;
        font-size:11.5px;font-weight:700;font-family:'Tajawal',sans-serif;
        cursor:pointer;transition:var(--ease);
    }
    .mc-action-btn i{font-size:11px}
    .mc-action-btn.promote{border-color:rgba(var(--s-rgb),.2);color:var(--success);background:var(--s-dim)}
    .mc-action-btn.promote:hover{background:rgba(var(--s-rgb),.18);border-color:rgba(var(--s-rgb),.5);box-shadow:var(--sh-s);transform:translateY(-2px)}
    .mc-action-btn.demote{border-color:rgba(var(--w-rgb),.2);color:var(--warn);background:var(--w-dim)}
    .mc-action-btn.demote:hover{background:rgba(var(--w-rgb),.18);border-color:rgba(var(--w-rgb),.45);box-shadow:var(--sh-w);transform:translateY(-2px)}
    .mc-action-btn.weapon{border-color:rgba(var(--p-rgb),.2);color:var(--p);background:var(--p-dim)}
    .mc-action-btn.weapon:hover{background:rgba(var(--p-rgb),.18);border-color:var(--ba);box-shadow:var(--sh-p);transform:translateY(-2px)}
    .mc-action-btn.pull{border-color:rgba(var(--p-rgb),.2);color:var(--p);background:var(--p-dim)}
    .mc-action-btn.pull:hover{background:rgba(var(--p-rgb),.18);border-color:var(--ba);box-shadow:var(--sh-p);transform:translateY(-2px)}
    .mc-action-btn.danger{border-color:rgba(var(--d-rgb),.2);color:var(--danger);background:var(--d-dim)}
    .mc-action-btn.danger:hover{background:rgba(var(--d-rgb),.18);border-color:rgba(var(--d-rgb),.5);box-shadow:var(--sh-d);transform:translateY(-2px)}
    
    /* Legacy icon buttons */
    .member-actions{display:flex;gap:4px;flex-shrink:0}
    .action-icon-btn{width:28px;height:28px;border-radius:7px;border:1px solid var(--b);background:var(--card);color:var(--t3);display:flex;align-items:center;justify-content:center;font-size:11px;cursor:pointer;transition:var(--ease)}
    .action-icon-btn:hover{transform:translateY(-1px)}
    .action-icon-btn.promote:hover{background:var(--s-dim);border-color:rgba(var(--s-rgb),.35);color:var(--success)}
    .action-icon-btn.demote:hover{background:var(--w-dim);border-color:rgba(var(--w-rgb),.35);color:var(--warn)}
    .action-icon-btn.weapon:hover{background:var(--p-dim);border-color:var(--ba);color:var(--p)}
    .action-icon-btn.pull:hover{background:rgba(var(--p-rgb),.15);border-color:var(--ba);color:var(--p)}
    .action-icon-btn.danger:hover{background:var(--d-dim);border-color:rgba(var(--d-rgb),.35);color:var(--danger)}
    
    /* 
       HIRING CATEGORY
     */
    .input-section{margin-bottom:8px}
    .id-input-row{display:grid;grid-template-columns:1fr;gap:8px}
    
    .rank-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:8px}
    .rank-card{
        background:var(--card);border:1px solid var(--b);border-radius:var(--r1);
        padding:10px 10px;display:flex;align-items:center;gap:10px;
        cursor:pointer;transition:var(--ease);position:relative;overflow:hidden;
    }
    .rank-card:hover{
        background:rgba(var(--p-rgb),.065);
        border-color:var(--ba);
        transform:translateY(-2px);
        box-shadow:0 8px 24px rgba(var(--black-rgb),.4);
    }
    .rank-card.selected{
        background:linear-gradient(100deg,rgba(var(--p-dark-rgb),.55),rgba(var(--p-rgb),.2));
        border-color:rgba(var(--p-rgb),.52);
        box-shadow:0 0 22px rgba(var(--p-rgb),.18);
    }
    .rank-card.selected::before{
        content:"";position:absolute;right:0;top:16%;bottom:16%;
        width:3px;background:var(--p-ac-grad);
        border-radius:2px;box-shadow:0 0 12px var(--p);
    }
    .rank-num{
        background:var(--p-dim);color:var(--p);
        font-size:11px;font-weight:900;
        width:22px;height:22px;border-radius:6px;
        display:flex;align-items:center;justify-content:center;flex-shrink:0;
        border:1px solid rgba(var(--p-rgb),.22);
    }
    .rank-lbl{color:var(--t1);font-size:12px;font-weight:700}
    
    .hiring-actions{display:flex;gap:10px;margin-top:4px}
    .hire-btn{
        flex:1;padding:12px 10px;border-radius:var(--r0);border:1px solid transparent;
        font-size:13px;font-weight:700;font-family:'Tajawal',sans-serif;
        display:flex;align-items:center;justify-content:center;gap:7px;
        cursor:pointer;transition:var(--ease);
        position:relative;overflow:hidden;
    }
    .hire-btn::after{
        content:"";position:absolute;inset:0;
        background:linear-gradient(105deg,transparent 30%,rgba(var(--white-rgb),.06) 50%,transparent 70%);
        transform:translateX(-100%);transition:.45s ease;pointer-events:none;
    }
    .hire-btn:not(:disabled):hover::after{transform:translateX(100%)}
    .hire-btn:disabled{opacity:.3;cursor:not-allowed}
    .hire-btn.info{background:var(--p-dim);border-color:rgba(var(--p-rgb),.28);color:var(--p)}
    .hire-btn.info:not(:disabled):hover{background:rgba(var(--p-rgb),.2);border-color:var(--ba);box-shadow:var(--sh-p);transform:translateY(-2px)}
    .hire-btn.success{background:var(--s-dim);border-color:rgba(var(--s-rgb),.3);color:var(--success)}
    .hire-btn.success:not(:disabled):hover{background:rgba(var(--s-rgb),.18);border-color:rgba(var(--s-rgb),.5);box-shadow:var(--sh-s);transform:translateY(-2px)}
    .hire-btn.danger{background:var(--d-dim);border-color:rgba(var(--d-rgb),.3);color:var(--danger)}
    .hire-btn.danger:not(:disabled):hover{background:rgba(var(--d-rgb),.18);border-color:rgba(var(--d-rgb),.5);box-shadow:var(--sh-d);transform:translateY(-2px)}
    
    /* Query Result Card */
    .query-result-card{
        background:linear-gradient(158deg,var(--bg-card1));
        border:1px solid var(--ba);border-radius:var(--r2);
        padding:18px 20px;display:flex;flex-direction:column;gap:12px;
        box-shadow:0 0 40px rgba(var(--p-rgb),.1);
        position:relative;overflow:hidden;
    }
    .query-result-card::before{
        content:"";position:absolute;top:0;left:0;right:0;height:2px;
        background:var(--p-line);
    }
    .qr-header{display:flex;gap:14px;align-items:flex-start}
    .qr-avatar{
        width:64px;height:64px;border-radius:14px;
        object-fit:cover;border:2px solid var(--ba);flex-shrink:0;
        box-shadow:0 0 24px rgba(var(--p-rgb),.22);
    }
    .qr-info{display:flex;flex-direction:column;gap:5px;flex:1}
    .qr-name{color:var(--t0);font-size:16px;font-weight:900}
    .qr-meta{display:flex;gap:6px;flex-wrap:wrap}
    .qr-rank{color:var(--t2);font-size:12px;font-weight:700}
    .qr-time{color:var(--t3);font-size:11.5px;font-weight:700;display:flex;align-items:center;gap:4px}
    .qr-time i{color:var(--p);font-size:10px}
    .qr-actions{display:flex;gap:8px}
    .qr-btn{flex:1;padding:9px 8px;border-radius:var(--r0);border:1px solid transparent;font-size:12px;font-weight:700;font-family:'Tajawal',sans-serif;display:flex;align-items:center;justify-content:center;gap:6px;cursor:pointer;transition:var(--ease)}
    .qr-btn.promote{background:var(--s-dim);border-color:rgba(var(--s-rgb),.28);color:var(--success)}
    .qr-btn.promote:hover{background:rgba(var(--s-rgb),.18);transform:translateY(-2px);box-shadow:var(--sh-s)}
    .qr-btn.demote{background:var(--w-dim);border-color:rgba(var(--w-rgb),.28);color:var(--warn)}
    .qr-btn.demote:hover{background:rgba(var(--w-rgb),.18);transform:translateY(-2px);box-shadow:var(--sh-w)}
    .qr-btn.weapon{background:var(--p-dim);border-color:var(--ba);color:var(--p)}
    .qr-btn.weapon:hover{background:rgba(var(--p-rgb),.2);transform:translateY(-2px);box-shadow:var(--sh-p)}
    
    /* 
       BULK CATEGORY
     */
    .bulk-section{
        background:var(--card);border:1px solid var(--b);border-radius:var(--r1);
        padding:18px;display:flex;flex-direction:column;gap:12px;
        position:relative;overflow:hidden;
    }
    .bulk-section::before{
        content:"";position:absolute;top:0;left:0;right:0;height:1px;
        background:var(--p-line);opacity:.2;
    }
    .bulk-btn{
        padding:13px 20px;border-radius:var(--r0);border:1px solid transparent;
        font-size:13px;font-weight:700;font-family:'Tajawal',sans-serif;
        display:flex;align-items:center;justify-content:center;gap:8px;
        cursor:pointer;transition:var(--ease);
        align-self:flex-start;min-width:160px;
        position:relative;overflow:hidden;
    }
    .bulk-btn:disabled{opacity:.3;cursor:not-allowed}
    /* Shine sweep on hover */
    .bulk-btn::after{
        content:"";position:absolute;inset:0;
        background:linear-gradient(105deg,transparent 30%,rgba(var(--white-rgb),.07) 50%,transparent 70%);
        transform:translateX(-100%);transition:.5s ease;pointer-events:none;
    }
    .bulk-btn:not(:disabled):hover::after{transform:translateX(100%)}
    .bulk-btn.info{background:var(--p-grad);color:#fff;box-shadow:var(--sh-p)}
    .bulk-btn.info:hover{transform:translateY(-2px);box-shadow:0 12px 32px rgba(var(--p-rgb),.48)}
    .bulk-btn.warn{background:var(--w-grad);color:#fff;box-shadow:var(--sh-w)}
    .bulk-btn.warn:not(:disabled):hover{transform:translateY(-2px);box-shadow:0 12px 32px rgba(var(--w-rgb),.42)}
    .bulk-btn.danger{background:var(--d-grad);color:#fff;box-shadow:var(--sh-d)}
    .bulk-btn.danger:not(:disabled):hover{transform:translateY(-2px);box-shadow:0 12px 32px rgba(var(--d-rgb),.44)}
    
    /* Weapon Grid */
    .weapon-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:8px}
    .weapon-card{
        background:var(--card);border:1px solid var(--b);border-radius:var(--r1);
        padding:14px 10px;display:flex;flex-direction:column;align-items:center;gap:7px;
        cursor:pointer;transition:var(--ease);position:relative;overflow:hidden;
    }
    .weapon-card i{font-size:22px;color:var(--t3);transition:var(--ease)}
    .weapon-card span{font-size:12px;font-weight:700;color:var(--t2);text-align:center}
    .weapon-card small{font-size:10px;color:var(--t3)}
    .weapon-card:hover{
        background:rgba(var(--p-rgb),.07);
        border-color:var(--ba);
        transform:translateY(-3px);
        box-shadow:0 12px 30px rgba(var(--black-rgb),.5);
    }
    .weapon-card:hover i{color:var(--p);filter:drop-shadow(0 0 8px rgba(var(--p-rgb),.65))}
    .weapon-card.selected{
        background:linear-gradient(135deg,rgba(var(--p-dark-rgb),.48),rgba(var(--p-rgb),.13));
        border-color:rgba(var(--p-rgb),.52);
        box-shadow:0 0 26px rgba(var(--p-rgb),.2);
    }
    .weapon-card.selected i{color:var(--p);filter:drop-shadow(0 0 12px var(--p))}
    .weapon-card.selected span{color:var(--t0)}
    
    /* 
       TREASURY CATEGORY
     */
    .treasury-balance-card{
        background:
            linear-gradient(rgba(var(--p-rgb),.04) 1px,transparent 1px),
            linear-gradient(90deg,rgba(var(--p-rgb),.04) 1px,transparent 1px),
            linear-gradient(145deg,rgba(5,6,24,.99),rgba(10,12,40,.98));
        background-size:26px 26px,26px 26px,auto;
        border:1px solid var(--ba);border-radius:var(--r2);
        padding:36px 20px;text-align:center;
        box-shadow:0 0 70px rgba(var(--p-rgb),.12);
        position:relative;overflow:hidden;
    }
    .treasury-balance-card::before{
        content:"";position:absolute;top:0;left:0;right:0;height:2px;
        background:var(--p-line);
    }
    .tb-label{
        color:var(--t3);font-size:10px;font-weight:800;
        text-transform:uppercase;letter-spacing:1.8px;margin-bottom:12px;
    }
    .tb-amount{
        font-size:54px;font-weight:900;line-height:1;
        filter:drop-shadow(0 0 24px currentColor) drop-shadow(0 0 5px currentColor);
    }
    .tb-currency{font-size:28px;font-weight:700;margin-inline-end:3px}
    
    .treasury-btns{display:grid;grid-template-columns:1fr 1fr;gap:14px}
    .t-big-btn{
        padding:32px 20px;border-radius:var(--r2);
        font-size:16px;font-weight:900;font-family:'Tajawal',sans-serif;
        display:flex;flex-direction:column;align-items:center;justify-content:center;gap:12px;
        cursor:pointer;transition:var(--ease);border:1px solid transparent;
        position:relative;overflow:hidden;letter-spacing:.4px;
    }
    .t-big-btn::after{
        content:"";position:absolute;inset:0;
        background:radial-gradient(ellipse at 50% 0%,currentColor,transparent 65%);
        opacity:.04;pointer-events:none;
    }
    .t-big-btn i{font-size:34px;transition:transform .3s ease,filter .3s ease}
    .t-big-btn span{font-size:15px;font-weight:800}
    .t-big-btn.deposit{
        background:linear-gradient(158deg,rgba(var(--s-rgb),.1),rgba(var(--s-rgb),.03));
        border-color:rgba(var(--s-rgb),.26);color:var(--success);
    }
    .t-big-btn.deposit:hover{
        background:linear-gradient(158deg,rgba(var(--s-rgb),.21),rgba(var(--s-rgb),.09));
        border-color:rgba(var(--s-rgb),.56);
        transform:translateY(-5px);box-shadow:var(--sh-s);
    }
    .t-big-btn.deposit:hover i{filter:drop-shadow(0 0 16px var(--success));transform:scale(1.22) translateY(-3px)}
    .t-big-btn.withdraw{
        background:linear-gradient(158deg,rgba(var(--d-rgb),.1),rgba(var(--d-rgb),.03));
        border-color:rgba(var(--d-rgb),.26);color:var(--danger);
    }
    .t-big-btn.withdraw:hover{
        background:linear-gradient(158deg,rgba(var(--d-rgb),.21),rgba(var(--d-rgb),.09));
        border-color:rgba(var(--d-rgb),.56);
        transform:translateY(-5px);box-shadow:var(--sh-d);
    }
    .t-big-btn.withdraw:hover i{filter:drop-shadow(0 0 16px var(--danger));transform:scale(1.22) translateY(-3px)}
    
    .treasury-log{display:flex;flex-direction:column;gap:8px}
    .log-list{display:flex;flex-direction:column;gap:5px;max-height:240px;overflow-y:auto}
    .log-row{
        display:grid;grid-template-columns:34px 1fr auto;gap:10px;align-items:center;
        background:var(--card);border:1px solid var(--b);border-radius:var(--r0);
        padding:9px 13px;transition:var(--ease);
    }
    .log-row:hover{border-color:var(--ba);background:rgba(var(--p-rgb),.04)}
    .log-icon{
        width:34px;height:34px;border-radius:9px;
        display:flex;align-items:center;justify-content:center;font-size:12px;flex-shrink:0;
    }
    .log-row.deposit .log-icon{background:var(--s-dim);color:var(--success)}
    .log-row.withdraw .log-icon{background:var(--d-dim);color:var(--danger)}
    .log-info{display:flex;flex-direction:column;gap:3px}
    .log-by{color:var(--t1);font-size:12.5px;font-weight:700}
    .log-date{color:var(--t3);font-size:10px;font-weight:600}
    .log-amount{font-size:14px;font-weight:900;flex-shrink:0}
    .log-amount.deposit{color:var(--success);filter:drop-shadow(0 0 6px rgba(var(--s-rgb),.4))}
    .log-amount.withdraw{color:var(--danger);filter:drop-shadow(0 0 6px rgba(var(--d-rgb),.4))}
    
    /* 
       MODALS
     */
    .modal-overlay{
        position:fixed;inset:0;
        display:flex;justify-content:center;align-items:center;z-index:99999;
        background:radial-gradient(ellipse at center,rgba(0,0,20,.75),rgba(0,0,8,.35));
    }
    .modal-box{
        width:470px;max-width:94vw;max-height:84vh;overflow-y:auto;
        background:
            linear-gradient(rgba(var(--p-rgb),.03) 1px,transparent 1px),
            linear-gradient(90deg,rgba(var(--p-rgb),.03) 1px,transparent 1px),
            linear-gradient(158deg,var(--bg-grad1));
        background-size:28px 28px,28px 28px,auto;
        border-radius:var(--r3);
        border:1px solid rgba(var(--p-rgb),.22);
        box-shadow:var(--sh),0 0 80px rgba(var(--p-rgb),.08);
        padding:24px;display:flex;flex-direction:column;gap:16px;
        position:relative;overflow:hidden;
    }
    .modal-box::before{
        content:"";position:absolute;top:0;left:0;right:0;height:2px;
        background:var(--p-line);
    }
    .modal-title{
        color:var(--t0);font-size:16px;font-weight:900;text-align:center;
        padding-bottom:14px;border-bottom:1px solid var(--b);
        letter-spacing:.3px;
    }
    .modal-weapon-grid{grid-template-columns:repeat(3,1fr)}
    .modal-footer{display:flex;gap:10px;margin-top:4px}
    .m-confirm{
        flex:1;padding:13px;border-radius:var(--r0);border:none;
        background:var(--p-grad);color:#fff;
        font-size:14px;font-weight:700;font-family:'Tajawal',sans-serif;
        cursor:pointer;transition:var(--ease);
        display:flex;align-items:center;justify-content:center;gap:7px;
        box-shadow:var(--sh-p);
        position:relative;overflow:hidden;
    }
    .m-confirm::after{
        content:"";position:absolute;inset:0;
        background:linear-gradient(105deg,transparent 30%,rgba(var(--white-rgb),.07) 50%,transparent 70%);
        transform:translateX(-100%);transition:.4s ease;pointer-events:none;
    }
    .m-confirm:not(:disabled):hover{transform:translateY(-2px);box-shadow:0 14px 36px rgba(var(--p-rgb),.48)}
    .m-confirm:not(:disabled):hover::after{transform:translateX(100%)}
    .m-confirm:disabled{opacity:.3;cursor:not-allowed}
    .m-confirm.danger{background:var(--d-grad);box-shadow:var(--sh-d)}
    .m-confirm.danger:hover{box-shadow:0 14px 36px rgba(var(--d-rgb),.44)}
    .m-cancel{
        flex:1;padding:13px;border-radius:var(--r0);
        border:1px solid rgba(var(--d-rgb),.22);background:var(--d-dim);color:var(--danger);
        font-size:14px;font-weight:700;font-family:'Tajawal',sans-serif;
        cursor:pointer;transition:var(--ease);
    }
    .m-cancel:hover{background:rgba(var(--d-rgb),.17);border-color:rgba(var(--d-rgb),.48);transform:translateY(-2px)}
    
    /* Confirm modal */
    .confirm-modal{align-items:center;text-align:center}
    .confirm-icon{
        font-size:46px;color:var(--warn);
        filter:drop-shadow(0 0 22px rgba(var(--w-rgb),.55));
        padding:8px 0;
    }
    .confirm-body{color:var(--t2);font-size:13px;font-weight:600;line-height:1.7}
    .confirm-amount-wrap{width:100%;margin-top:2px}
    .confirm-amount-input{text-align:center;font-size:22px;font-weight:900;letter-spacing:1px;padding:14px 18px}
    
    /* 
       BROADCAST OVERLAY
     */
    .bc-overlay{
        position:fixed;top:50%;right:22px;transform:translateY(-50%);
        display:flex;flex-direction:column;z-index:99999;pointer-events:none;
    }
    .bc-box{
        pointer-events:auto;position:relative;
        width:308px;max-width:88vw;
        background:
            linear-gradient(rgba(var(--p-rgb),.025) 1px,transparent 1px),
            linear-gradient(90deg,rgba(var(--p-rgb),.025) 1px,transparent 1px),
            linear-gradient(160deg,var(--bg-grad2));
        background-size:26px 26px,26px 26px,auto;
        border:1px solid var(--gc,var(--p));border-radius:var(--r2);
        box-shadow:0 0 0 1px rgba(var(--white-rgb),.04),0 26px 60px rgba(var(--black-rgb),.95);
        padding:20px 20px 14px;
        display:flex;flex-direction:column;align-items:center;gap:11px;overflow:hidden;
    }
    .bc-box::before{
        content:"";position:absolute;top:0;left:8%;right:8%;height:2px;
        background:linear-gradient(90deg,transparent,var(--gc,var(--p)),transparent);
        opacity:.85;
    }
    .bc-logo-wrap{position:relative;width:64px;height:64px;margin-top:2px}
    .bc-logo{width:64px;height:64px;border-radius:50%;object-fit:cover;border:2px solid var(--gc,var(--p));box-shadow:0 0 22px rgba(var(--black-rgb),.5)}
    .bc-logo-placeholder{width:64px;height:64px;border-radius:50%;background:rgba(var(--white-rgb),.04);border:2px solid var(--gc,var(--p));display:flex;align-items:center;justify-content:center;color:var(--gc,var(--p));font-size:24px}
    .bc-logo-ring{position:absolute;inset:-7px;border-radius:50%;border:2px solid var(--gc,var(--p));opacity:.2;animation:bcPulse 2.8s ease-in-out infinite}
    @keyframes bcPulse{0%,100%{transform:scale(1);opacity:.2}50%{transform:scale(1.15);opacity:.05}}
    .bc-gang-name{font-size:15px;font-weight:900;text-align:center;letter-spacing:.5px;filter:drop-shadow(0 0 10px currentColor)}
    .bc-divider{display:flex;align-items:center;gap:8px;width:86%}
    .bc-line{flex:1;height:1px;background:linear-gradient(90deg,transparent,var(--gc,var(--p)),transparent);opacity:.5}
    .bc-divider-icon{font-size:13px;opacity:.75}
    .bc-message{color:var(--bc-msg-color);font-size:12px;font-weight:700;text-align:center;line-height:1.6;word-break:break-word;background:rgba(var(--white-rgb),.04);border:1px solid rgba(var(--white-rgb),.07);border-radius:11px;padding:10px 13px;width:100%}
    .bc-footer{display:flex;align-items:center;gap:6px;color:#4e6070;font-size:11px;font-weight:600}
    .bc-progress{width:100%;height:3px;background:rgba(var(--white-rgb),.05);border-radius:2px;overflow:hidden;margin-top:2px}
    .bc-progress-bar{height:100%;border-radius:2px;animation:bcDown 12s linear forwards;opacity:.75}
    @keyframes bcDown{from{width:100%}to{width:0%}}
    
    /* 
       TOAST NOTIFICATIONS
     */
    #notify-container{
        position:fixed;top:50%;right:22px;transform:translateY(-50%);
        display:flex;flex-direction:column;gap:9px;z-index:999999;pointer-events:none;
    }
    .toast-item{
        position:relative;width:308px;max-width:92vw;
        display:flex;align-items:center;gap:12px;padding:11px 14px;
        border-radius:14px;
        background:linear-gradient(158deg,var(--bg-grad2));
        border:1px solid rgba(var(--white-rgb),.06);
        box-shadow:0 12px 40px rgba(var(--black-rgb),.85);
        color:#fff;overflow:hidden;direction:rtl;
    }
    .toast-item::before{content:"";position:absolute;top:0;left:15%;right:15%;height:2px;border-radius:2px;opacity:.9}
    .toast-item::after{content:"";position:absolute;right:0;top:14%;bottom:14%;width:3px;border-radius:2px}
    .toast-item.success::before{background:linear-gradient(90deg,transparent,var(--success),transparent)}
    .toast-item.error::before{background:linear-gradient(90deg,transparent,var(--danger),transparent)}
    .toast-item.warning::before{background:linear-gradient(90deg,transparent,var(--warn),transparent)}
    .toast-item.success::after{background:var(--success);box-shadow:0 0 12px var(--success)}
    .toast-item.error::after{background:var(--danger);box-shadow:0 0 12px var(--danger)}
    .toast-item.warning::after{background:var(--warn);box-shadow:0 0 12px var(--warn)}
    .toast-item.success{border-color:rgba(var(--s-rgb),.18)}
    .toast-item.error{border-color:rgba(var(--d-rgb),.18)}
    .toast-item.warning{border-color:rgba(var(--w-rgb),.18)}
    .toast-icon-wrap{flex-shrink:0;width:36px;height:36px;border-radius:10px;display:flex;align-items:center;justify-content:center}
    .toast-item.success .toast-icon-wrap{background:rgba(var(--s-rgb),.12);color:var(--success)}
    .toast-item.error   .toast-icon-wrap{background:rgba(var(--d-rgb),.12);color:var(--danger)}
    .toast-item.warning .toast-icon-wrap{background:rgba(var(--w-rgb),.12);color:var(--warn)}
    .toast-icon{font-size:16px}
    .toast-text{flex:1;display:flex;flex-direction:column;gap:2px}
    .toast-title{font-size:13px;font-weight:800;color:#eef2ff}
    .toast-msg{font-size:11px;font-weight:600;color:#6a80ab;word-break:break-word}
    .toast-progress{position:absolute;bottom:0;left:0;right:0;height:2px;overflow:hidden}
    .toast-progress-bar{height:100%;width:100%;animation:toastProgress 4.5s linear forwards}
    .toast-item.success .toast-progress-bar{background:var(--success)}
    .toast-item.error   .toast-progress-bar{background:var(--danger)}
    .toast-item.warning .toast-progress-bar{background:var(--warn)}
    @keyframes toastProgress{from{width:100%}to{width:0%}}
    
    /* 
       VUE TRANSITIONS
     */
    .fade-enter-active,.fade-leave-active{transition:opacity .3s ease}
    .fade-enter,.fade-leave-to{opacity:0}
    .zoom-enter-active{animation:zoomIn .22s cubic-bezier(.34,1.56,.64,1)}
    .zoom-leave-active{animation:zoomOut .15s ease-in forwards}
    @keyframes zoomIn{from{transform:scale(.86);opacity:0}to{transform:scale(1);opacity:1}}
    @keyframes zoomOut{from{transform:scale(1);opacity:1}to{transform:scale(.93);opacity:0}}
    .broadcast-in-enter-active{animation:bcSlideIn .4s cubic-bezier(.34,1.56,.64,1)}
    .broadcast-in-leave-active{animation:bcSlideOut .25s ease-in forwards}
    @keyframes bcSlideIn{from{transform:translateX(70px);opacity:0}to{transform:translateX(0);opacity:1}}
    @keyframes bcSlideOut{from{transform:translateX(0);opacity:1}to{transform:translateX(55px);opacity:0}}
    .toast-anim-enter-active{animation:toastIn .3s cubic-bezier(.34,1.56,.64,1)}
    .toast-anim-leave-active{animation:toastOut .2s ease-in forwards}
    @keyframes toastIn{from{transform:translateX(55px);opacity:0}to{transform:translateX(0);opacity:1}}
    @keyframes toastOut{from{opacity:1}to{opacity:0;transform:translateX(35px)}}
    .slide-down-enter-active{transition:all .22s cubic-bezier(.4,0,.2,1)}
    .slide-down-leave-active{transition:all .16s ease-in}
    .slide-down-enter,.slide-down-leave-to{opacity:0;transform:translateY(-8px)}
    
    /* 
       SCROLLBARS
     */
    ::-webkit-scrollbar{width:3px}
    ::-webkit-scrollbar-track{background:transparent}
    ::-webkit-scrollbar-thumb{background:rgba(var(--p-rgb),.3);border-radius:3px}
    ::-webkit-scrollbar-thumb:hover{background:rgba(var(--p-rgb),.55)}
    *{scrollbar-width:thin;scrollbar-color:rgba(var(--p-rgb),.28) transparent}
    
    /* 
       ADMIN PANEL
     */
    #adminContainer{
        width:1200px;height:680px;
        display:flex;flex-direction:column;
        border-radius:var(--r3);
        box-shadow:var(--sh),0 0 110px rgba(var(--adm-rgb),.1);
        overflow:hidden;
        position:fixed;
        top:50%;left:50%;
        transform:translate(-50%,-50%);
        z-index:9000;
        outline:1px solid rgba(var(--adm-rgb),.09);
        outline-offset:3px;
    }
    .admin-header{
        background:linear-gradient(115deg,var(--bg-adm-head-stops))!important;
        border-bottom-color:rgba(var(--adm-rgb),.32)!important;
    }
    .admin-header::after{
        background:var(--adm-line)!important;
        opacity:.82!important;
    }
    .admin-header::before{
        background:linear-gradient(180deg,transparent,rgba(var(--adm-rgb),.2),transparent)!important;
    }
    .admin-header .header-glow-orb{
        background:radial-gradient(ellipse,rgba(var(--adm-rgb),.22) 0%,transparent 70%)!important;
    }
    .admin-header .header-gang-name{
        background:linear-gradient(135deg,#ff9999,#e74c3c,#ff6b6b)!important;
        -webkit-background-clip:text!important;background-clip:text!important;
        filter:drop-shadow(0 0 16px rgba(var(--adm-rgb),.4))!important;
    }
    .admin-header-icon{
        width:76px;height:76px;border-radius:16px;
        background:linear-gradient(135deg,rgba(var(--adm-rgb),.18),rgba(var(--d-deep-rgb),.08));
        border:2px solid rgba(var(--adm-rgb),.42);
        display:flex;align-items:center;justify-content:center;
        font-size:30px;color:var(--adm,#e74c3c);
        box-shadow:0 0 32px rgba(var(--adm-rgb),.28),0 4px 16px rgba(var(--black-rgb),.6);
        transition:var(--ease-b);
    }
    
    /* 
       WARNING DETAIL MODAL
     */
    .warning-detail-modal{max-width:450px;width:100%}
    .wdm-icon{
        width:64px;height:64px;border-radius:50%;
        background:rgba(var(--d-rgb),.11);border:2px solid rgba(var(--d-rgb),.34);
        display:flex;align-items:center;justify-content:center;
        font-size:28px;color:var(--danger);
        margin:0 auto 10px;
        box-shadow:0 0 32px rgba(var(--d-rgb),.22);
        animation:warnIcon 2s ease infinite;
    }
    .wdm-body{display:flex;flex-direction:column;gap:10px;width:100%}
    .wdm-row{
        display:flex;gap:10px;align-items:flex-start;
        padding:10px 14px;border-radius:var(--r0);
        background:rgba(var(--white-rgb),.025);border:1px solid var(--b);
    }
    .wdm-lbl{color:var(--t3);font-size:10.5px;font-weight:800;white-space:nowrap;display:flex;align-items:center;gap:5px;min-width:100px}
    .wdm-val{color:var(--t1);font-size:12.5px;font-weight:700;flex:1;word-break:break-word}
    .wdm-nav{display:flex;align-items:center;justify-content:space-between;margin-top:6px}
    .wdm-nav-label{color:var(--t3);font-size:11px;font-weight:700}
    .wdm-nav-btns{display:flex;gap:6px}
    .wdm-nav-btn{width:32px;height:32px;border-radius:8px;border:1px solid var(--b);background:var(--card);color:var(--t2);display:flex;align-items:center;justify-content:center;font-size:11px;cursor:pointer;transition:var(--ease)}
    .wdm-nav-btn:not(:disabled):hover{background:var(--card-h);border-color:var(--ba);color:var(--p)}
    .wdm-nav-btn:disabled{opacity:.28;cursor:not-allowed}
    
    /* 
       ADMIN  SHARED HELPERS
     */
    .section-label-sm{
        color:var(--t2);font-size:9.5px;font-weight:800;
        text-transform:uppercase;letter-spacing:1.4px;
        margin-bottom:9px;display:flex;align-items:center;gap:7px;
    }
    
    .gang-pill-row{display:flex;flex-wrap:wrap;gap:7px;margin-bottom:12px}
    .gang-pill{
        padding:7px 14px;border-radius:20px;
        border:1px solid var(--b);background:var(--card);
        color:var(--t2);font-size:12.5px;font-weight:700;
        cursor:pointer;transition:var(--ease);
        display:flex;align-items:center;gap:6px;
    }
    .gang-pill:hover{border-color:var(--ba);background:var(--card-h);color:var(--t1)}
    .gang-pill.active{
        color:var(--t0);
        border-color:rgba(var(--p-rgb),.46);
        background:linear-gradient(135deg,rgba(var(--p-dark-rgb),.38),rgba(var(--p-rgb),.15));
        box-shadow:0 0 18px rgba(var(--p-rgb),.12);
    }
    .pill-cnt{
        background:rgba(var(--white-rgb),.09);color:var(--t2);
        font-size:9.5px;font-weight:900;padding:1px 6px;border-radius:10px;
    }
    .pill-cnt.warn{background:rgba(var(--d-rgb),.15);color:var(--danger)}
    .pill-cnt.pts{background:rgba(var(--w-rgb),.15);color:var(--warn)}
    
    /* 
       ADMIN  OVERVIEW GRID
     */
    .admin-gangs-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(265px,1fr));gap:14px}
    .admin-gang-card{
        background:
            linear-gradient(rgba(var(--p-rgb),.025) 1px,transparent 1px),
            linear-gradient(90deg,rgba(var(--p-rgb),.025) 1px,transparent 1px),
            var(--card);
        background-size:24px 24px,24px 24px,auto;
        border:1px solid var(--b);border-radius:var(--r2);
        padding:18px;display:flex;flex-direction:column;gap:14px;
        transition:var(--ease);position:relative;overflow:hidden;
    }
    .admin-gang-card::before{
        content:"";position:absolute;top:0;left:0;right:0;height:2px;
        background:linear-gradient(90deg,transparent,var(--gc),transparent);
        opacity:.65;
    }
    .admin-gang-card:hover{
        border-color:rgba(var(--white-rgb),.1);
        box-shadow:0 10px 34px rgba(var(--black-rgb),.55);
        transform:translateY(-2px);
    }
    .agc-header{display:flex;gap:13px;align-items:center}
    .agc-logo{
        width:52px;height:52px;border-radius:13px;
        object-fit:cover;border:2px solid rgba(var(--white-rgb),.09);flex-shrink:0;
        box-shadow:0 4px 18px rgba(var(--black-rgb),.5);transition:var(--ease);
    }
    .admin-gang-card:hover .agc-logo{border-color:rgba(var(--white-rgb),.2)}
    .agc-info{display:flex;flex-direction:column;gap:6px;flex:1;min-width:0}
    .agc-name{font-size:15px;font-weight:900;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
    .agc-badges{display:flex;gap:5px;flex-wrap:wrap}
    .agc-stats{display:flex;flex-wrap:wrap;gap:8px}
    .agc-stat{
        display:flex;align-items:center;gap:5px;
        color:var(--t2);font-size:11.5px;font-weight:700;
        background:rgba(var(--white-rgb),.03);border:1px solid var(--b);
        border-radius:6px;padding:4px 9px;
        transition:var(--ease);
    }
    .agc-stat i{font-size:10px;color:var(--t3)}
    
    /* 
       ADMIN  TREASURY LIST
     */
    .adm-treasury-list{display:flex;flex-direction:column;gap:8px}
    .adm-treasury-row{
        display:flex;align-items:center;justify-content:space-between;
        padding:16px 20px;border-radius:var(--r1);
        background:var(--card);border:1px solid var(--b);
        transition:var(--ease);position:relative;overflow:hidden;
    }
    .adm-treasury-row::before{
        content:"";position:absolute;right:0;top:0;bottom:0;width:2px;
        background:var(--p-ac-grad);opacity:0;transition:var(--ease);
    }
    .adm-treasury-row:hover{border-color:var(--ba);background:var(--card-h)}
    .adm-treasury-row:hover::before{opacity:.5}
    .adm-tr-info{display:flex;align-items:center;gap:13px}
    .adm-tr-logo{width:38px;height:38px;border-radius:10px;object-fit:cover;border:1.5px solid rgba(var(--white-rgb),.09)}
    .adm-tr-name{font-size:14px;font-weight:900}
    .adm-tr-balance{
        font-size:24px;font-weight:900;
        filter:drop-shadow(0 0 12px currentColor);
    }
    
    /* 
       ADMIN  WARNING FORM & LIST
     */
    .warning-form{
        background:rgba(var(--d-rgb),.04);
        border:1px solid rgba(var(--d-rgb),.2);
        border-radius:var(--r1);padding:16px;
        display:flex;flex-direction:column;gap:10px;
        margin-bottom:14px;position:relative;overflow:hidden;
    }
    .warning-form::before{
        content:"";position:absolute;top:0;left:0;right:0;height:1px;
        background:linear-gradient(90deg,transparent,rgba(var(--d-rgb),.55),transparent);
    }
    .warn-form-row{display:flex;gap:8px;align-items:flex-end}
    .w-half,.flex1{flex:1}
    
    .warnings-list{display:flex;flex-direction:column;gap:8px}
    .warning-card{
        background:linear-gradient(135deg,rgba(var(--d-rgb),.07),rgba(var(--d-deep-rgb),.03));
        border:1px solid rgba(var(--d-rgb),.22);border-radius:var(--r1);
        overflow:hidden;transition:var(--ease);position:relative;
    }
    .warning-card::before{
        content:"";position:absolute;top:0;left:0;right:0;height:1px;
        background:linear-gradient(90deg,transparent,rgba(var(--d-rgb),.45),transparent);
    }
    .warning-card:hover{border-color:rgba(var(--d-rgb),.42);box-shadow:0 4px 22px rgba(var(--d-rgb),.1)}
    .wc-header{display:flex;align-items:flex-start;gap:11px;padding:13px 16px}
    .wc-icon{font-size:16px;color:var(--danger);flex-shrink:0;margin-top:2px;filter:drop-shadow(0 0 6px rgba(var(--d-rgb),.55))}
    .wc-info{flex:1;display:flex;flex-direction:column;gap:4px}
    .wc-title{color:var(--t0);font-size:13px;font-weight:900}
    .wc-meta{display:flex;gap:10px;flex-wrap:wrap}
    .wc-meta span{color:var(--t3);font-size:10.5px;font-weight:700}
    .wc-del-btn{
        width:32px;height:32px;border-radius:8px;
        border:1px solid rgba(var(--d-rgb),.25);background:rgba(var(--d-rgb),.09);
        color:var(--danger);display:flex;align-items:center;justify-content:center;font-size:12px;
        cursor:pointer;transition:var(--ease);flex-shrink:0;
    }
    .wc-del-btn:hover{background:rgba(var(--d-rgb),.22);border-color:rgba(var(--d-rgb),.55);transform:scale(1.08);box-shadow:var(--sh-d)}
    .wc-reason{
        padding:9px 16px;border-top:1px solid rgba(var(--d-rgb),.12);
        color:var(--t2);font-size:12px;font-weight:600;
        background:rgba(var(--d-rgb),.025);
    }
    
    /* 
       ADMIN  POINTS & RANKING
     */
    .points-section{
        background:var(--card);border:1px solid var(--b);border-radius:var(--r1);
        padding:16px;display:flex;flex-direction:column;gap:11px;
    }
    .points-input-row{display:flex;gap:8px;align-items:flex-end}
    
    .ranking-table{display:flex;flex-direction:column;gap:8px}
    .rank-row{
        display:flex;align-items:center;gap:13px;
        padding:14px 18px;border-radius:var(--r1);
        background:var(--card);border:1px solid var(--b);
        transition:var(--ease);position:relative;overflow:hidden;
    }
    .rank-row::before{
        content:"";position:absolute;right:0;top:0;bottom:0;width:2px;
        background:var(--p-ac-grad);opacity:0;transition:var(--ease);
    }
    .rank-row:hover{border-color:var(--ba);background:var(--card-h)}
    .rank-row:hover::before{opacity:.65}
    .rank-pos{font-size:17px;font-weight:900;width:35px;text-align:center;flex-shrink:0}
    .rank-logo{width:42px;height:42px;border-radius:11px;object-fit:cover;border:1.5px solid rgba(var(--white-rgb),.09);flex-shrink:0}
    .rank-info{flex:1;display:flex;flex-direction:column;gap:4px}
    .rank-lbl-name{font-size:14px;font-weight:900}
    .rank-meta-row{display:flex;gap:12px}
    .rank-meta-row span{color:var(--t3);font-size:11px;font-weight:700;display:flex;align-items:center;gap:4px}
    .rank-meta-row i{font-size:9px}
    .rank-pts{
        font-size:26px;font-weight:900;flex-shrink:0;text-align:center;
        filter:drop-shadow(0 0 12px currentColor);
    }
    .rank-pts-lbl{font-size:10px;font-weight:700;display:block;text-align:center;color:var(--t3);filter:none}
    
    .refresh-btn{
        padding:5px 12px;border-radius:var(--r0);
        border:1px solid var(--b);background:var(--card);
        color:var(--t2);font-size:11px;font-weight:700;
        font-family:'Tajawal',sans-serif;cursor:pointer;transition:var(--ease);
        display:inline-flex;align-items:center;gap:5px;margin-right:auto;
    }
    .refresh-btn:hover{border-color:var(--ba);color:var(--p);background:var(--card-h);box-shadow:var(--sh-p)}
    
    /* 
       GANG RANKING CATEGORY
     */
    .cat-ranking{display:flex;flex-direction:column;gap:12px}
    
    /* تبويبات */
    .rank-tabs{
        display:flex;gap:6px;align-items:center;
        background:var(--card);border:1px solid var(--b);
        border-radius:var(--r1);padding:6px;
    }
    .rank-tab-btn{
        flex:1;padding:8px 0;border-radius:var(--r0);
        border:1px solid transparent;background:transparent;
        color:var(--t2);font-size:12px;font-weight:800;
        font-family:'Tajawal',sans-serif;cursor:pointer;
        display:flex;align-items:center;justify-content:center;gap:6px;
        transition:var(--ease);
    }
    .rank-tab-btn i{font-size:10px}
    .rank-tab-btn.active{
        background:rgba(var(--p-rgb),.14);border-color:rgba(var(--p-rgb),.35);
        color:var(--p);box-shadow:0 0 12px rgba(var(--p-rgb),.15);
    }
    .rank-tab-btn:not(.active):hover{background:rgba(var(--white-rgb),.04);color:var(--t1)}
    .rank-refresh-btn{
        width:34px;height:34px;border-radius:var(--r0);flex-shrink:0;
        border:1px solid var(--b);background:transparent;
        color:var(--t3);font-size:12px;cursor:pointer;
        display:flex;align-items:center;justify-content:center;
        transition:var(--ease);margin-right:auto;
    }
    .rank-refresh-btn:hover{border-color:var(--ba);color:var(--p);background:rgba(var(--p-rgb),.08)}
    .rank-refresh-btn:disabled{opacity:.4;cursor:default}
    
    /* قائمة */
    .rank-list{display:flex;flex-direction:column;gap:8px}
    
    .gr-row{
        display:flex;align-items:center;gap:12px;
        padding:13px 16px;border-radius:var(--r1);
        background:var(--card);border:1px solid var(--b);
        transition:var(--ease);position:relative;overflow:hidden;
    }
    .gr-row::before{
        content:"";position:absolute;right:0;top:0;bottom:0;width:3px;
        opacity:0;transition:var(--ease);
        background:var(--p-ac-grad);
    }
    .gr-row:hover{border-color:var(--ba);background:var(--card-h)}
    .gr-row:hover::before{opacity:.7}
    
    /* مميّز: عصابة اللاعب */
    .gr-row.self{
        border-color:rgba(var(--p-rgb),.45);
        background:rgba(var(--p-rgb),.07);
        box-shadow:0 0 16px rgba(var(--p-rgb),.1);
    }
    .gr-row.self::before{opacity:.9}
    
    /* ألوان المراكز */
    .gr-row.gold .gr-pos, .gr-crow.gold { color:#ffd700 }
    .gr-row.silver .gr-pos, .gr-crow.silver { color:#c0c0c0 }
    .gr-row.bronze .gr-pos, .gr-crow.bronze { color:#cd7f32 }
    
    .gr-pos{
        width:30px;text-align:center;flex-shrink:0;
        font-size:15px;font-weight:900;color:var(--t3);
    }
    .gr-crown{font-size:16px;filter:drop-shadow(0 0 8px currentColor)}
    .gr-crown.gold  {color:#ffd700}
    .gr-crown.silver{color:#c0c0c0}
    .gr-crown.bronze{color:#cd7f32}
    
    .gr-logo{
        width:40px;height:40px;border-radius:10px;
        object-fit:cover;border:1.5px solid rgba(var(--white-rgb),.08);
        flex-shrink:0;
    }
    .gr-info{flex:1;display:flex;flex-direction:column;gap:4px;min-width:0}
    .gr-name{font-size:13px;font-weight:900;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
    .gr-meta{display:flex;gap:10px;flex-wrap:wrap}
    .gr-meta span{color:var(--t3);font-size:10.5px;font-weight:700;display:flex;align-items:center;gap:4px}
    .gr-meta i{font-size:9px}
    
    .gr-score{
        flex-shrink:0;text-align:center;display:flex;flex-direction:column;
        align-items:center;gap:1px;min-width:52px;
    }
    .gr-score-val{
        font-size:22px;font-weight:900;line-height:1;
        filter:drop-shadow(0 0 10px currentColor);
    }
    .gr-score.pts .gr-score-val{color:var(--warn)}
    .gr-score.time .gr-score-val{color:var(--p);font-size:18px}
    .gr-score.time .gr-score-val small{font-size:11px;font-weight:700;margin-right:1px}
    .gr-score-lbl{font-size:9.5px;font-weight:700;color:var(--t3)}
    
    /* loading / empty */
    .rank-loading,.rank-empty{
        display:flex;flex-direction:column;align-items:center;justify-content:center;
        gap:10px;padding:40px 0;color:var(--t3);font-size:13px;font-weight:700;
    }
    .rank-loading i,.rank-empty i{font-size:28px;color:var(--t4)}
    .rank-empty i{color:rgba(var(--w-rgb),.35)}
    
    
    /* 
       LAUNDRY OVERLAY
     */
    .laundry-overlay {
        position: fixed;
        bottom: 26px;
        left: 50%;
        right: auto;
        transform: translateX(-50%);
        width: min(360px, 92vw);
        z-index: 99999;
        pointer-events: none;
        font-family: 'Tajawal', sans-serif;
    }
    
    .laundry-panel {
        background: linear-gradient(160deg, rgba(10, 18, 30, 0.97) 0%, rgba(6, 12, 20, 0.97) 100%);
        border: 1px solid rgba(77, 127, 255, 0.25);
        border-radius: 18px;
        padding: 18px 20px 16px;
        box-shadow:
            0 0 0 1px rgba(77, 127, 255, 0.07),
            0 12px 40px rgba(0, 0, 0, 0.8),
            0 0 60px rgba(77, 127, 255, 0.05) inset;
        pointer-events: auto;
        position: relative;
        overflow: hidden;
        color: #fff;
    }
    
    .laundry-panel::before {
        content: '';
        position: absolute;
        inset: 0;
        border-radius: 18px;
        background: linear-gradient(135deg, rgba(77,127,255,0.06) 0%, transparent 60%);
        pointer-events: none;
    }
    
    /* animated top accent line */
    .laundry-panel::after {
        content: '';
        position: absolute;
        top: 0; left: 10%; right: 10%;
        height: 2px;
        background: linear-gradient(90deg, transparent, #4d7fff, transparent);
        border-radius: 0 0 4px 4px;
        animation: laundryTopLine 2.5s ease-in-out infinite;
    }
    
    @keyframes laundryTopLine {
        0%, 100% { opacity: .4; transform: scaleX(.6); }
        50%       { opacity: 1;  transform: scaleX(1);  }
    }
    
    /*  Header  */
    .laundry-header {
        display: flex !important;
        flex-direction: column !important;
        align-items: center;
        justify-content: center;
        gap: 6px;
        margin-bottom: 18px;
        width: 100%;
    }
    
    .laundry-title {
        font-size: 15px;
        font-weight: 900;
        color: #fff;
        letter-spacing: .4px;
        text-align: center;
        width: 100%;
    }
    
    .laundry-icon-wrap {
        width: 42px;
        height: 42px;
        border-radius: 12px;
        background: linear-gradient(135deg, rgba(77,127,255,0.18), rgba(12,32,112,0.4));
        border: 1px solid rgba(77,127,255,0.28);
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }
    
    .laundry-icon {
        font-size: 19px;
        color: #4d7fff;
    }
    
    .laundry-icon.pulsing {
        animation: laundryIconPulse 1.2s ease-in-out infinite alternate;
    }
    
    @keyframes laundryIconPulse {
        from { transform: scale(1);    filter: drop-shadow(0 0 3px rgba(77,127,255,.5)); }
        to   { transform: scale(1.18); filter: drop-shadow(0 0 10px rgba(77,127,255,.95)); }
    }
    
    .laundry-title .fa-circle-check { color: #4d7fff; margin-left: 4px; }
    
    /*  Amounts row  */
    .laundry-amounts {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 14px;
        padding: 11px 14px;
        background: rgba(255,255,255,0.04);
        border-radius: 10px;
        border: 1px solid rgba(255,255,255,0.06);
    }
    
    .laundry-amount {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 3px;
    }
    
    .laundry-amount i    { font-size: 15px; }
    .laundry-amount span { font-size: 14px; font-weight: 900; line-height: 1; }
    .laundry-amount small{ font-size: 9px; opacity: .55; text-transform: uppercase; letter-spacing: .5px; }
    
    .laundry-amount.dirty i,
    .laundry-amount.dirty span { color: #ff6b6b; }
    
    .laundry-amount.clean i,
    .laundry-amount.clean span { color: #85b8ff; }
    
    .laundry-arrow-anim {
        color: rgba(255,255,255,.35);
        font-size: 13px;
        animation: laundryArrow 1s ease-in-out infinite;
    }
    
    @keyframes laundryArrow {
        0%, 100% { transform: translateX(0);    opacity: .35; }
        50%       { transform: translateX(-4px); opacity: .7;  }
    }
    
    /*  Progress bar (below timer)  */
    .laundry-progress-section {
        display: flex;
        flex-direction: column;
        align-items: stretch;
        gap: 6px;
        margin-bottom: 13px;
    }
    
    .laundry-bar {
        width: 100%;
        height: 7px;
        background: rgba(255,255,255,0.08);
        border-radius: 99px;
        overflow: hidden;
    }
    
    .laundry-bar-fill {
        height: 100%;
        background: linear-gradient(90deg, #2f5de0, #4d7fff);
        border-radius: 99px;
        transition: width 0.9s cubic-bezier(.4,0,.2,1);
        position: relative;
        min-width: 4px;
    }
    
    .laundry-bar-dot {
        position: absolute;
        right: -1px;
        top: 50%;
        transform: translateY(-50%);
        width: 14px;
        height: 14px;
        background: #4d7fff;
        border-radius: 50%;
        filter: blur(5px);
        opacity: .9;
        animation: laundryDotPulse .8s ease-in-out infinite alternate;
    }
    
    @keyframes laundryDotPulse {
        from { opacity: .5; transform: translateY(-50%) scale(.8); }
        to   { opacity: 1;  transform: translateY(-50%) scale(1.3); }
    }
    
    .laundry-pct {
        font-size: 11px;
        font-weight: 700;
        color: #85b8ff;
        text-align: center;
        display: block;
    }
    
    /*  Timer  */
    .laundry-timer {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 7px;
        margin-bottom: 13px;
        color: rgba(255,255,255,.65);
    }
    
    .laundry-timer i { color: #4d7fff; font-size: 12px; }
    
    .laundry-time-val {
        font-size: 22px;
        font-weight: 900;
        color: #fff;
        font-variant-numeric: tabular-nums;
        letter-spacing: 2px;
    }
    
    .laundry-timer small { font-size: 10px; opacity: .5; }
    
    /*  Cancel button  */
    .laundry-cancel-btn {
        width: 100%;
        padding: 7px;
        border-radius: 9px;
        border: 1px solid rgba(255,80,80,.3);
        background: rgba(255,50,50,.1);
        color: #ff7070;
        font-size: 12px;
        font-weight: 700;
        font-family: 'Tajawal', sans-serif;
        cursor: pointer;
        transition: background .2s, border-color .2s;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 6px;
    }
    
    .laundry-cancel-btn:hover {
        background: rgba(255,50,50,.22);
        border-color: rgba(255,80,80,.55);
    }
    
    /*  Done section  */
    .laundry-done-section {
        text-align: center;
        padding: 4px 0 2px;
    }
    
    .laundry-done-amount {
        font-size: 26px;
        font-weight: 900;
        color: #85b8ff;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 10px;
        margin-bottom: 4px;
        animation: laundryDoneAnim .45s cubic-bezier(.34,1.56,.64,1) both;
    }
    
    @keyframes laundryDoneAnim {
        from { transform: scale(.65); opacity: 0; }
        to   { transform: scale(1);   opacity: 1; }
    }
    
    .laundry-done-amount i { font-size: 22px; }
    
    .laundry-done-sub {
        font-size: 11px;
        opacity: .5;
        color: #fff;
        text-transform: uppercase;
        letter-spacing: 1px;
    }
    
    /*  Slide transition  */
    .laundry-slide-enter-active { animation: laundrySlideIn .4s cubic-bezier(.34,1.56,.64,1) both; }
    .laundry-slide-leave-active { animation: laundrySlideOut .25s ease-in both; }
    
    @keyframes laundrySlideIn {
        from { transform: translate(-50%, 0) translateX(110%); opacity: 0; }
        to   { transform: translate(-50%, 0) translateX(0);    opacity: 1; }
    }
    
    @keyframes laundrySlideOut {
        from { transform: translate(-50%, 0) translateX(0);    opacity: 1; }
        to   { transform: translate(-50%, 0) translateX(110%); opacity: 0; }
    }
    
    /* ══════════ LAUNDRY E-KEY HINT ══════════ */
    .laundry-hint-box {
        position: fixed;
        top: 50%;
        bottom: auto;
        right: 40px;
        left: auto;
        transform: translateY(-50%);
        display: flex !important;
        flex-direction: row !important;
        align-items: center;
        gap: 10px;
        background: linear-gradient(135deg, rgba(10,18,40,0.96) 0%, rgba(6,14,50,0.96) 100%);
        border: 1px solid rgba(77, 127, 255, 0.35);
        border-radius: 14px;
        padding: 11px 18px;
        pointer-events: none;
        font-family: 'Tajawal', sans-serif;
        box-shadow:
            0 4px 24px rgba(0,0,0,0.55),
            0 0 20px rgba(77, 127, 255, 0.08) inset;
        z-index: 99998;
    }
    
    .laundry-hint-icon {
        color: #4d7fff;
        font-size: 16px;
        flex-shrink: 0;
        filter: drop-shadow(0 0 6px rgba(77,127,255,.6));
        animation: laundryIconPulse 1.4s ease-in-out infinite alternate;
    }
    
    .laundry-hint-label {
        font-size: 13px;
        font-weight: 700;
        color: rgba(255,255,255,0.9);
        white-space: nowrap;
    }
    
    .laundry-hint-key-badge {
        width: 30px;
        height: 30px;
        border-radius: 7px;
        background: linear-gradient(135deg, rgba(77,127,255,0.2), rgba(77,127,255,0.08));
        border: 1.5px solid rgba(77, 127, 255, 0.55);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 14px;
        font-weight: 900;
        color: #4d7fff;
        flex-shrink: 0;
        box-shadow: 0 2px 8px rgba(77,127,255,0.2);
        text-shadow: 0 0 8px rgba(77,127,255,0.7);
    }
    
    /* hint-slide: متجر الأسلحة (bottom center, left:50%) */
    .hint-slide-enter-active {
        animation: hintSlideIn 0.22s ease-out both;
        will-change: transform, opacity;
    }
    .hint-slide-leave-active {
        animation: hintSlideOut 0.16s ease-in both;
        will-change: transform, opacity;
    }
    @keyframes hintSlideIn {
        from { transform: translateX(-50%) translateY(10px); opacity: 0; }
        to   { transform: translateX(-50%) translateY(0);    opacity: 1; }
    }
    @keyframes hintSlideOut {
        from { transform: translateX(-50%) translateY(0);    opacity: 1; }
        to   { transform: translateX(-50%) translateY(10px); opacity: 0; }
    }
    
    /* hint-slide-right: غسيل الأموال (top 50%, right:40px) */
    .hint-slide-right-enter-active {
        animation: hintSlideRightIn 0.22s ease-out both;
        will-change: transform, opacity;
    }
    .hint-slide-right-leave-active {
        animation: hintSlideRightOut 0.16s ease-in both;
        will-change: transform, opacity;
    }
    @keyframes hintSlideRightIn {
        from { transform: translateY(-50%) translateX(18px); opacity: 0; }
        to   { transform: translateY(-50%) translateX(0);    opacity: 1; }
    }
    @keyframes hintSlideRightOut {
        from { transform: translateY(-50%) translateX(0);    opacity: 1; }
        to   { transform: translateY(-50%) translateX(18px); opacity: 0; }
    }

    /* territory-hint-slide-right: الاستحلال (top 50%, right:40px) */
    .territory-hint-slide-right-enter-active {
        animation: terrHintSlideRightIn 0.22s ease-out both;
        will-change: transform, opacity;
    }
    .territory-hint-slide-right-leave-active {
        animation: terrHintSlideRightOut 0.16s ease-in both;
        will-change: transform, opacity;
    }
    @keyframes terrHintSlideRightIn {
        from { transform: translateY(-50%) translateX(18px); opacity: 0; }
        to   { transform: translateY(-50%) translateX(0);    opacity: 1; }
    }
    @keyframes terrHintSlideRightOut {
        from { transform: translateY(-50%) translateX(0);    opacity: 1; }
        to   { transform: translateY(-50%) translateX(18px); opacity: 0; }
    }

    /* territory-slide: قائمة الاستحلال */
    .territory-slide-enter-active { animation: terrCaptureSlideIn .4s cubic-bezier(.34,1.56,.64,1) both; }
    .territory-slide-leave-active { animation: terrCaptureSlideOut .25s ease-in both; }

    @keyframes terrCaptureSlideIn {
        from { transform: translate(-50%, 0) translateX(110%); opacity: 0; }
        to   { transform: translate(-50%, 0) translateX(0);    opacity: 1; }
    }

    @keyframes terrCaptureSlideOut {
        from { transform: translate(-50%, 0) translateX(0);    opacity: 1; }
        to   { transform: translate(-50%, 0) translateX(110%); opacity: 0; }
    }
    
    /* 
       ════════════════════════════════════════
       متجر الأسلحة  —  Shop Redesign
       ════════════════════════════════════════
    */
    
    /* ── wrapper ── */
    .cat-shop { padding: 0 0.25rem; }
    
    .shop-loading {
        display: flex; align-items: center; justify-content: center; gap: 0.6rem;
        padding: 2.5rem 1rem; color: rgba(255,255,255,0.4); font-size: 0.9rem;
    }
    
    /* ────────────────────────────────────────
       Gang Header
    ──────────────────────────────────────── */
    .shop-gang-header {
        display: flex; align-items: center; gap: 0.85rem;
        background: linear-gradient(135deg, rgba(255,255,255,0.05), rgba(255,255,255,0.02));
        border: 1px solid rgba(255,255,255,0.09);
        border-radius: 16px; padding: 0.85rem 1.1rem;
        margin-bottom: 1rem; position: relative; overflow: hidden;
    }
    .shop-gang-header::before {
        content: '';
        position: absolute; left: 0; top: 0; bottom: 0; width: 3px;
        background: var(--gang-color, #4d7fff);
        border-radius: 3px 0 0 3px;
    }
    
    .sgh-logo-wrap { flex-shrink: 0; width: 46px; height: 46px; }
    .sgh-logo {
        width: 46px; height: 46px; border-radius: 11px; object-fit: cover;
        border: 1px solid rgba(255,255,255,0.12);
    }
    .sgh-logo-fallback {
        width: 46px; height: 46px; border-radius: 11px;
        background: rgba(255,255,255,0.07); border: 1px solid rgba(255,255,255,0.1);
        display: flex; align-items: center; justify-content: center;
        font-size: 1.3rem; color: rgba(255,255,255,0.35);
    }
    .sgh-info { flex: 1; min-width: 0; }
    .sgh-gang-name {
        font-size: 1.1rem; font-weight: 900; line-height: 1.2;
        white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
    }
    .sgh-subtitle {
        font-size: 0.76rem; color: rgba(255,255,255,0.4); margin-top: 3px;
        display: flex; align-items: center; gap: 4px;
    }
    .sgh-status-pill {
        font-size: 0.74rem; font-weight: 700; padding: 0.24rem 0.65rem;
        border-radius: 20px; display: flex; align-items: center; gap: 0.3rem;
        flex-shrink: 0; white-space: nowrap;
    }
    .sgh-status-pill.owned    { background: rgba(34,197,94,0.14);  color: #4ade80; border: 1px solid rgba(34,197,94,0.3);  }
    .sgh-status-pill.locked   { background: rgba(239,68,68,0.12);  color: #f87171; border: 1px solid rgba(239,68,68,0.25); }
    .sgh-status-pill.available{ background: rgba(59,130,246,0.14); color: #60a5fa; border: 1px solid rgba(59,130,246,0.3); }
    
    /* ────────────────────────────────────────
       Lock Card
    ──────────────────────────────────────── */
    .shop-lock-card {
        display: flex; align-items: center; gap: 1rem; flex-wrap: wrap;
        background: rgba(239,68,68,0.06); border: 1px solid rgba(239,68,68,0.2);
        border-radius: 14px; padding: 1.2rem 1.1rem;
    }
    .slc-icon { font-size: 2rem; color: rgba(239,68,68,0.55); flex-shrink: 0; }
    .slc-body { flex: 1; min-width: 0; }
    .slc-title { font-weight: 800; color: #fff; font-size: 1rem; }
    .slc-desc  { font-size: 0.84rem; color: rgba(255,255,255,0.55); margin-top: 3px; }
    .slc-pts   { display: flex; flex-direction: column; align-items: flex-end; gap: 2px; }
    .slc-pts-label { font-size: 0.7rem; color: rgba(255,255,255,0.38); }
    .slc-pts-val   { font-size: 1.3rem; color: rgb(255, 0, 0); font-weight: 800; }
    
    /* ────────────────────────────────────────
       Available Card
    ──────────────────────────────────────── */
    .shop-available-card {
        display: flex; align-items: center; gap: 1rem; flex-wrap: wrap;
        background: rgba(34,197,94,0.05); border: 1px solid rgba(34,197,94,0.2);
        border-radius: 14px; padding: 1.1rem 1.1rem;
    }
    .sac-left  { display: flex; align-items: center; gap: 0.85rem; flex: 1; min-width: 0; }
    .sac-icon  { font-size: 1.8rem; color: #4ade80; flex-shrink: 0; }
    .sac-title { font-weight: 800; color: #fff; font-size: 1rem; }
    .sac-cost  { font-size: 0.84rem; color: rgba(255,255,255,0.55); margin-top: 3px; }
    
    .shop-purchase-btn {
        padding: 0.7rem 1.4rem; border: none; border-radius: 11px; color: #fff;
        font-size: 0.92rem; font-weight: 800; cursor: pointer; font-family: inherit;
        transition: 0.2s; display: flex; align-items: center; gap: 0.5rem;
        white-space: nowrap; flex-shrink: 0;
    }
    .shop-purchase-btn:hover { filter: brightness(1.12); transform: scale(1.03); }
    
    .shop-no-perm {
        font-size: 0.82rem; color: rgba(255,255,255,0.38);
        display: flex; align-items: center; gap: 0.4rem;
    }
    
    /* ────────────────────────────────────────
       Manage Section — Item Cards
    ──────────────────────────────────────── */
    .shop-manage-section { padding: 0.1rem 0; }
    .shop-items-grid    { display: flex; flex-direction: column; gap: 0.7rem; }
    
    .shop-item-card {
        background: rgba(255,255,255,0.04);
        border: 1px solid rgba(255,255,255,0.08);
        border-radius: 15px; padding: 0.95rem 1rem;
        display: flex; flex-direction: column; gap: 0.75rem;
        transition: background 0.18s, transform 0.18s;
        position: relative; overflow: hidden;
    }
    .shop-item-card:hover {
        background: rgba(255,255,255,0.07);
        transform: translateY(-1px);
    }
    /* Colored left accent strip */
    .shop-item-card::after {
        content: ''; position: absolute; left: 0; top: 0; bottom: 0;
        width: 3px; background: var(--gang-color, #4d7fff);
        border-radius: 3px 0 0 3px; opacity: 0.65;
    }
    
    /* Top row: icon + name + stock */
    .sic-top  { display: flex; align-items: center; gap: 0.75rem; }
    .sic-icon-wrap {
        width: 40px; height: 40px; border-radius: 10px; flex-shrink: 0;
        background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.1);
        display: flex; align-items: center; justify-content: center;
        font-size: 1.1rem; color: rgba(255,255,255,0.5);
    }
    .sic-meta {
        flex: 1; min-width: 0;
        display: flex; align-items: center; justify-content: space-between; gap: 0.5rem; flex-wrap: wrap;
    }
    .sic-name { font-weight: 800; font-size: 0.95rem; color: #fff; }
    .sic-stock {
        font-size: 0.77rem; font-weight: 700; padding: 0.18rem 0.5rem;
        border-radius: 7px; display: flex; align-items: center; gap: 0.28rem; white-space: nowrap;
    }
    .sic-stock.ok    { background: rgba(34,197,94,0.12);  color: #4ade80; }
    .sic-stock.low   { background: rgba(234,179,8,0.12);  color: #facc15; }
    .sic-stock.empty { background: rgba(239,68,68,0.12);  color: #f87171; }
    
    /* Price row */
    .sic-price-row {
        display: flex; align-items: stretch; gap: 0;
        background: rgba(255,255,255,0.04);
        border: 1px solid rgba(255,255,255,0.07);
        border-radius: 10px; overflow: hidden;
    }
    .sic-price-block,
    .sic-restock-block,
    .sic-qty-block {
        display: flex; flex-direction: column; gap: 3px;
        padding: 0.5rem 0.7rem; flex: 1;
    }
    .sic-divider {
        width: 1px; background: rgba(255,255,255,0.07); flex-shrink: 0;
    }
    .sic-price-lbl   { font-size: 0.68rem; color: rgba(255,255,255,0.38); }
    .sic-price-val   { font-size: 0.92rem; font-weight: 800; color: #34d399; }
    .sic-restock-val { font-size: 0.92rem; font-weight: 800; color: rgba(255,255,255,0.65); }
    .sic-qty-val     { font-size: 0.92rem; font-weight: 800; color: #60a5fa; }
    
    /* Actions */
    .sic-actions    { display: flex; gap: 0.5rem; align-items: center; flex-wrap: wrap; }
    .sic-price-edit { display: flex; gap: 0.35rem; align-items: center; flex: 1; min-width: 0; }
    .sic-price-input { flex: 1; padding: 0.42rem 0.65rem; font-size: 0.82rem; min-width: 0; }
    
    .sic-set-btn {
        padding: 0.42rem 0.8rem; display: flex; align-items: center; gap: 0.3rem;
        background: rgba(59,130,246,0.18); border: 1px solid rgba(59,130,246,0.35);
        border-radius: 8px; color: #60a5fa; cursor: pointer;
        font-size: 0.82rem; font-weight: 700; font-family: inherit;
        transition: 0.18s; flex-shrink: 0; white-space: nowrap;
    }
    .sic-set-btn:hover { background: rgba(59,130,246,0.32); }
    
    .sic-restock-btn {
        padding: 0.42rem 0.9rem; display: flex; align-items: center; gap: 0.3rem;
        background: rgba(34,197,94,0.14); border: 1px solid rgba(34,197,94,0.3);
        border-radius: 8px; color: #4ade80; cursor: pointer;
        font-size: 0.82rem; font-weight: 700; font-family: inherit;
        transition: 0.18s; flex-shrink: 0; white-space: nowrap;
    }
    .sic-restock-btn:hover { background: rgba(34,197,94,0.28); }
    
    /* ────────────────────────────────────────
       Shop Buy Overlay Modal  (citizen-facing)
    ──────────────────────────────────────── */
    /* ════════════════════════════════════════════
       SHOP BUY MODAL  (citizen-facing)
       ════════════════════════════════════════════ */
    
    /* Transparent backdrop — no blur */
    .sbc-overlay {
        position: fixed; inset: 0;
        display: flex; align-items: center; justify-content: center;
        z-index: 500; pointer-events: all;
        background: transparent;
    }
    
    /* Main box */
    .sbc-box {
        width: 600px; max-height: 86vh;
        background: linear-gradient(170deg, #0e0f17 0%, #13141f 55%, #15172a 100%);
        border: 1.5px solid var(--gc, #4d7fff);
        border-radius: 22px; overflow: hidden;
        display: flex; flex-direction: column;
        box-shadow:
            0 40px 100px rgba(0,0,0,0.95),
            0 0 0 1px rgba(255,255,255,0.03),
            0 0 60px var(--gc-dim, rgba(77,127,255,.14));
        animation: zoomIn 0.26s cubic-bezier(.34,1.56,.64,1);
        position: relative;
    }
    
    /* ── Header ── */
    .sbc-header {
        flex-shrink: 0; position: relative;
        padding: 1.6rem 1.4rem 1.4rem;
        border-bottom: 1px solid rgba(255,255,255,0.06);
        overflow: hidden;
    }
    .sbc-header-glow {
        position: absolute; inset: 0; pointer-events: none;
    }
    
    /* Logo */
    .sbc-logo-wrap {
        width: 72px; height: 72px; border-radius: 18px; flex-shrink: 0;
        background: rgba(255,255,255,0.05);
        border: 2px solid var(--gc, #4d7fff);
        display: flex; align-items: center; justify-content: center;
        overflow: hidden; position: relative; z-index: 1;
    }
    .sbc-logo { width: 100%; height: 100%; object-fit: cover; }
    
    /* Text block */
    .sbc-header { display: flex; align-items: center; gap: 1.2rem; }
    .sbc-header-text { flex: 1; min-width: 0; position: relative; z-index: 1; }
    .sbc-gang-name {
        font-size: 1.7rem; font-weight: 900; line-height: 1.1;
        white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        text-shadow: 0 0 28px currentColor;
        letter-spacing: -0.5px;
    }
    .sbc-gang-sub {
        font-size: 0.8rem; color: rgba(255,255,255,0.42);
        margin-top: 5px; display: flex; align-items: center; gap: 0.4rem;
    }
    .sbc-avail-badge {
        display: inline-flex; align-items: center; gap: 0.4rem;
        font-size: 0.72rem; font-weight: 700;
        padding: 0.22rem 0.7rem; border-radius: 30px;
        border: 1px solid;
        margin-top: 8px;
    }
    
    /* Close button */
    .sbc-close-btn {
        position: relative; z-index: 2;
        flex-shrink: 0;
        width: 36px; height: 36px; border-radius: 10px;
        background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.1);
        color: rgba(255,255,255,0.5); cursor: pointer; font-size: 1rem;
        display: flex; align-items: center; justify-content: center;
        transition: 0.18s; align-self: flex-start;
    }
    .sbc-close-btn:hover {
        background: rgba(239,68,68,0.2); border-color: rgba(239,68,68,0.4);
        color: #f87171;
    }
    
    /* divider laser-line at bottom of header */
    .sbc-header-divider {
        position: absolute; bottom: 0; left: 5%; right: 5%; height: 1.5px;
        opacity: 0.55;
    }
    
    /* ── Items List ── */
    .sbc-list {
        overflow-y: auto; flex: 1;
        padding: 1rem 1.1rem; display: flex; flex-direction: column; gap: 0.65rem;
    }
    .sbc-list::-webkit-scrollbar { width: 4px; }
    .sbc-list::-webkit-scrollbar-track { background: transparent; }
    .sbc-list::-webkit-scrollbar-thumb {
        background: var(--gc-mid, rgba(77,127,255,.35)); border-radius: 4px;
    }
    
    /* Empty state */
    .sbc-empty {
        display: flex; flex-direction: column; align-items: center; gap: 0.9rem;
        padding: 3.5rem 1rem; color: rgba(255,255,255,0.2); text-align: center;
    }
    .sbc-empty i { font-size: 3.2rem; opacity: 0.2; }
    
    /* ── Weapon Card ── */
    .sbc-card {
        display: flex; align-items: center; gap: 1rem;
        background: rgba(255,255,255,0.03);
        border: 1px solid rgba(255,255,255,0.07);
        border-radius: 16px; padding: 0.9rem 1rem;
        transition: background 0.18s, transform 0.16s, border-color 0.18s;
    }
    .sbc-card:not(.disabled):hover {
        background: rgba(255,255,255,0.065);
        transform: translateX(-3px);
    }
    .sbc-card.disabled { opacity: 0.35; pointer-events: none; }
    
    /* Weapon icon */
    .sbc-card-icon {
        width: 56px; height: 56px; border-radius: 14px; flex-shrink: 0;
        background: rgba(255,255,255,0.05); border: 1.5px solid rgba(255,255,255,0.1);
        display: flex; align-items: center; justify-content: center;
        font-size: 1.45rem; color: rgba(255,255,255,0.35);
        transition: 0.18s;
    }
    
    /* Card body */
    .sbc-card-body { flex: 1; min-width: 0; }
    .sbc-card-name {
        font-size: 1rem; font-weight: 800; color: #fff;
        white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        margin-bottom: 6px;
    }
    .sbc-card-tags { display: flex; align-items: center; gap: 0.45rem; flex-wrap: wrap; }
    .sbc-tag {
        font-size: 0.7rem; font-weight: 700;
        padding: 0.18rem 0.55rem; border-radius: 6px;
        display: flex; align-items: center; gap: 0.28rem;
        white-space: nowrap;
    }
    .sbc-tag.ammo    { background: rgba(99,179,237,0.12); color: #63b3ed; }
    .sbc-tag.no-ammo { background: rgba(255,255,255,0.06); color: rgba(255,255,255,0.28); }
    .sbc-tag.stock.ok    { background: rgba(34,197,94,0.12);  color: #4ade80; }
    .sbc-tag.stock.low   { background: rgba(234,179,8,0.12);  color: #facc15; }
    .sbc-tag.stock.empty { background: rgba(239,68,68,0.12);  color: #f87171; }
    
    /* Right action area */
    .sbc-card-action {
        display: flex; flex-direction: column; align-items: flex-end; gap: 8px;
        flex-shrink: 0;
    }
    .sbc-card-price {
        font-size: 1.18rem; font-weight: 900;
        color: rgba(255,255,255,0.28);
        letter-spacing: 0.3px;
        transition: color 0.18s;
    }
    
    /* Buy button */
    .sbc-buy-btn {
        padding: 0.52rem 1.15rem;
        border: none; border-radius: 12px;
        color: #fff; cursor: pointer;
        font-size: 0.88rem; font-weight: 800; font-family: inherit;
        display: flex; align-items: center; gap: 0.45rem;
        transition: 0.2s; white-space: nowrap;
        background: rgba(120,120,120,0.18);
    }
    .sbc-buy-btn:disabled {
        background: rgba(120,120,120,0.12) !important;
        cursor: not-allowed; color: rgba(255,255,255,0.22);
        box-shadow: none !important;
    }
    .sbc-buy-btn:not(:disabled):hover {
        filter: brightness(1.18); transform: scale(1.07);
    }
    
    /* ── Footer ── */
    .sbc-footer {
        flex-shrink: 0; padding: 0.6rem 1.1rem;
        border-top: 1px solid rgba(255,255,255,0.05);
        display: flex; align-items: center; gap: 0.5rem;
        font-size: 0.72rem; color: rgba(255,255,255,0.18);
    }
    
    /* ── E-KEY HINT BAR ── */
    .shop-hint-bar {
        position: fixed; bottom: 5.5rem; left: 50%; transform: translateX(-50%);
        background: #000;
        border: 1px solid rgba(255,200,0,0.35); border-radius: 14px;
        padding: 0.55rem 1.4rem; color: #fff; font-size: 0.92rem;
        display: flex; align-items: center; gap: 0.75rem; z-index: 200;
        box-shadow: 0 6px 28px rgba(0,0,0,0.75); pointer-events: none;
    }
    .shop-hint-key {
        width: 28px; height: 28px; border-radius: 7px;
        background: rgba(255,255,255,0.1); border: 1.5px solid rgba(255,255,255,0.35);
        display: flex; align-items: center; justify-content: center;
        font-size: 0.85rem; font-weight: 900; color: #fff; flex-shrink: 0;
    }
    .shop-hint-icon { color: rgba(255,200,0,0.8); font-size: 1rem; }
    .shop-hint-text { color: rgba(255,255,255,0.8); }
    
    /*  Dirty Treasury Card  */
    .dirty-treasury-card {
        background: linear-gradient(135deg, rgba(180,120,0,0.18), rgba(80,50,0,0.25));
        border: 1.5px solid rgba(255,193,7,0.4);
        border-radius: 14px;
        padding: 14px 16px;
        margin: 12px 0 4px;
    }
    .dtc-header {
        display: flex;
        align-items: center;
        gap: 12px;
        margin-bottom: 12px;
    }
    .dtc-icon {
        font-size: 2rem;
        color: #ffc107;
        flex-shrink: 0;
    }
    .dtc-label {
        font-size: 0.75rem;
        color: rgba(255,255,255,0.55);
        margin-bottom: 2px;
    }
    .dtc-amount {
        font-size: 1.5rem;
        font-weight: 700;
        color: #ffc107;
        letter-spacing: 0.5px;
    }
    .dtc-currency {
        font-size: 0.85rem;
        margin-right: 3px;
        opacity: 0.8;
    }
    .dtc-actions {
        display: flex;
        flex-direction: column;
        gap: 8px;
    }
    .dtc-btn {
        border: none;
        border-radius: 8px;
        padding: 8px 14px;
        font-size: 0.82rem;
        font-weight: 600;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 6px;
        transition: opacity 0.15s;
    }
    .dtc-btn:hover { opacity: 0.85; }
    .dtc-btn.all {
        background: linear-gradient(135deg, #b8860b, #e0a800);
        color: #fff;
        width: 100%;
        justify-content: center;
    }
    .dtc-partial {
        display: flex;
        gap: 8px;
    }
    .dtc-input {
        flex: 1;
        background: rgba(255,255,255,0.07);
        border: 1px solid rgba(255,193,7,0.35);
        border-radius: 8px;
        color: #fff;
        padding: 7px 10px;
        font-size: 0.82rem;
        outline: none;
        min-width: 0;
    }
    .dtc-input::placeholder { color: rgba(255,255,255,0.35); }
    .dtc-input:focus { border-color: rgba(255,193,7,0.7); }
    .dtc-btn.partial {
        background: rgba(255,193,7,0.2);
        border: 1px solid rgba(255,193,7,0.4);
        color: #ffc107;
        flex-shrink: 0;
    }
    
    /* ════════════════════════════════════════════
       CAT-DIRTY — Dirty Money Category
    ════════════════════════════════════════════ */
    .cat-dirty {
        display: flex;
        flex-direction: column;
        gap: 14px;
        padding: 4px 2px;
    }
    
    /* ── Hero balance card ── */
    .dirty-hero-card {
        background: linear-gradient(135deg, rgba(180,120,0,0.22), rgba(60,35,0,0.32));
        border: 1.5px solid rgba(255,193,7,0.45);
        border-radius: 16px;
        padding: 22px 20px 18px;
        text-align: center;
    }
    .dirty-hero-icon {
        font-size: 2.2rem;
        color: #ffc107;
        margin-bottom: 6px;
    }
    .dirty-hero-label {
        font-size: 0.72rem;
        color: rgba(255,255,255,0.5);
        letter-spacing: 0.4px;
        margin-bottom: 6px;
        text-transform: uppercase;
    }
    .dirty-hero-balance {
        font-size: 2.2rem;
        font-weight: 800;
        color: #ffc107;
        letter-spacing: 1px;
        line-height: 1;
    }
    .dirty-hero-currency {
        font-size: 1rem;
        opacity: 0.75;
        margin-right: 4px;
    }
    
    /* ── Action buttons ── */
    .dirty-actions {
        display: flex;
        flex-direction: column;
        gap: 10px;
    }
    .dirty-btn-all {
        width: 100%;
        background: linear-gradient(135deg, #b8860b, #e0a800);
        color: #fff;
        border: none;
        border-radius: 10px;
        padding: 11px 16px;
        font-size: 0.88rem;
        font-weight: 700;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
        transition: opacity 0.15s, transform 0.12s;
    }
    .dirty-btn-all:hover { opacity: 0.88; transform: translateY(-1px); }
    .dirty-partial-row {
        display: flex;
        gap: 8px;
    }
    .dirty-input {
        flex: 1;
        background: rgba(255,255,255,0.07);
        border: 1px solid rgba(255,193,7,0.35);
        border-radius: 9px;
        color: #fff;
        padding: 9px 12px;
        font-size: 0.83rem;
        outline: none;
        min-width: 0;
        transition: border-color 0.15s;
    }
    .dirty-input::placeholder { color: rgba(255,255,255,0.3); }
    .dirty-input:focus { border-color: rgba(255,193,7,0.75); }
    .dirty-btn-partial {
        background: rgba(255,193,7,0.18);
        border: 1px solid rgba(255,193,7,0.45);
        border-radius: 9px;
        color: #ffc107;
        padding: 9px 14px;
        font-size: 0.83rem;
        font-weight: 600;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 6px;
        flex-shrink: 0;
        transition: opacity 0.15s;
    }
    .dirty-btn-partial:hover { opacity: 0.85; }
    
    /* ── Empty state ── */
    .dirty-empty {
        text-align: center;
        padding: 28px 16px;
        color: rgba(255,255,255,0.35);
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 10px;
    }
    .dirty-empty i { font-size: 2.4rem; color: rgba(255,193,7,0.3); }
    .dirty-empty span { font-size: 0.82rem; }
    
    /* ── Loading ── */
    .dirty-loading {
        text-align: center;
        padding: 24px;
        color: rgba(255,193,7,0.6);
        font-size: 1.4rem;
    }
    
    /* ── Log section ── */
    .dirty-log-section .section-label {
        font-size: 0.72rem;
        font-weight: 600;
        color: rgba(255,255,255,0.4);
        letter-spacing: 0.5px;
        text-transform: uppercase;
        margin-bottom: 8px;
        display: flex;
        align-items: center;
        gap: 6px;
    }
    .dirty-log-list {
        display: flex;
        flex-direction: column;
        gap: 6px;
    }
    .dirty-log-row {
        display: flex;
        align-items: center;
        gap: 10px;
        background: rgba(255,255,255,0.04);
        border-radius: 10px;
        padding: 9px 12px;
        border-right: 3px solid transparent;
        transition: background 0.12s;
    }
    .dirty-log-row:hover { background: rgba(255,255,255,0.07); }
    .dirty-log-row.revenue { border-right-color: #28c76f; }
    .dirty-log-row.withdraw { border-right-color: #ff9f43; }
    
    .dirty-log-icon {
        width: 28px;
        height: 28px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 0.75rem;
        flex-shrink: 0;
    }
    .dirty-log-row.revenue .dirty-log-icon {
        background: rgba(40,199,111,0.15);
        color: #28c76f;
    }
    .dirty-log-row.withdraw .dirty-log-icon {
        background: rgba(255,159,67,0.15);
        color: #ff9f43;
    }
    .dirty-log-info {
        flex: 1;
        min-width: 0;
    }
    .dirty-log-who {
        font-size: 0.8rem;
        font-weight: 600;
        color: rgba(255,255,255,0.85);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }
    .dirty-log-cid {
        font-size: 0.7rem;
        font-weight: 400;
        color: rgba(255,255,255,0.4);
        margin-right: 4px;
    }
    .dirty-log-note {
        font-size: 0.7rem;
        color: rgba(255,255,255,0.4);
        margin-top: 1px;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }
    .dirty-log-date {
        font-size: 0.65rem;
        color: rgba(255,255,255,0.3);
        margin-top: 2px;
    }
    .dirty-log-amount {
        font-size: 0.88rem;
        font-weight: 700;
        flex-shrink: 0;
    }
    .dirty-log-amount.revenue { color: #28c76f; }
    .dirty-log-amount.withdraw { color: #ff9f43; }
    
    /* ── CID badge in treasury log ── */
    .log-cid {
        font-size: 0.68rem;
        font-weight: 400;
        color: rgba(255,255,255,0.38);
        margin-right: 4px;
    }
    
    /* 
       CAT-OUTFIT  Gang Outfit Category
     */
    .cat-outfit {
        display: flex;
        flex-direction: column;
        gap: 16px;
        padding: 4px 0;
    }
    
    .outfit-loading-state {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 10px;
        padding: 60px 0;
        color: rgba(255,255,255,0.45);
        font-size: 1.1rem;
    }
    
    .outfit-loading-state i {
        font-size: 2rem;
        color: var(--accent, #4d7fff);
    }
    
    /* 
       Admin Shops & Dirty Treasury Tab
     */
    .cat-admin-shops .section-label{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
    .small-action-btn{padding:5px 14px;border-radius:8px;border:1px solid rgba(var(--p-rgb),.35);background:var(--p-dim);color:var(--p);font-size:.8rem;cursor:pointer;transition:.2s}
    .small-action-btn:hover{background:rgba(var(--p-rgb),.18);transform:translateY(-1px)}
    .admin-shops-list{display:flex;flex-direction:column;gap:14px;margin-top:10px}
    .admin-shop-card{
        background:rgba(255,255,255,.03);
        border:1px solid rgba(255,255,255,.10);
        background:color-mix(in srgb, var(--gc) 6%, transparent);
        border-color:color-mix(in srgb, var(--gc) 22%, transparent);
        border-radius:14px;
        padding:16px;
        display:flex;
        flex-direction:column;
        gap:10px;
        transition:.2s;
    }
    .admin-shop-card:hover{
        border-color:color-mix(in srgb, var(--gc) 40%, transparent);
        background:color-mix(in srgb, var(--gc) 10%, transparent);
    }
    .ash-header{display:flex;align-items:center;gap:12px}
    .ash-logo-wrap{width:44px;height:44px;border-radius:10px;border:1px solid rgba(var(--gc),.35);background:rgba(var(--gc),.12);display:flex;align-items:center;justify-content:center;overflow:hidden;flex-shrink:0}
    .ash-logo{width:100%;height:100%;object-fit:cover;border-radius:9px}
    .ash-title{display:flex;flex-direction:column;gap:4px;min-width:0}
    .ash-gang-name{font-weight:700;font-size:1rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
    .ash-badge{display:inline-flex;align-items:center;padding:2px 10px;border-radius:20px;font-size:.73rem;font-weight:600;border:1px solid}
    .ash-badge-open{background:rgba(46,213,115,.12);border-color:rgba(46,213,115,.35);color:#2ed573}
    .ash-badge-closed{background:rgba(255,165,0,.12);border-color:rgba(255,165,0,.35);color:#ffa500}
    .ash-badge-none{background:rgba(255,255,255,.06);border-color:rgba(255,255,255,.15);color:rgba(255,255,255,.5)}
    .ash-row{display:flex;align-items:center;gap:8px;font-size:.88rem;color:rgba(255,255,255,.75)}
    .ash-icon-dirty{color:#e0b800}
    .ash-dirty-val{color:#ffe066;font-weight:700;margin-right:auto}
    .ash-items{display:flex;flex-direction:column;gap:5px;background:rgba(0,0,0,.18);border-radius:10px;padding:10px}
    .ash-item-row{display:flex;align-items:center;gap:8px;font-size:.82rem}
    .ash-item-label{flex:1;color:rgba(255,255,255,.8)}
    .ash-item-stock{color:#74b9ff;font-weight:600;min-width:60px;text-align:center}
    .ash-item-price{color:#55efc4;font-weight:600;min-width:70px;text-align:left}
    .ash-actions{display:flex;gap:8px;flex-wrap:wrap;margin-top:4px}
    .ash-btn{flex:1;min-width:110px;padding:7px 14px;border-radius:9px;border:1px solid;font-size:.82rem;font-weight:600;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:6px;transition:.2s;background:transparent}
    .ash-btn.success{border-color:rgba(46,213,115,.35);color:#2ed573}
    .ash-btn.success:hover{background:rgba(46,213,115,.12);transform:translateY(-1px)}
    .ash-btn.warn{border-color:rgba(255,165,0,.35);color:#ffa500}
    .ash-btn.warn:hover{background:rgba(255,165,0,.12);transform:translateY(-1px)}
    .ash-btn.danger{border-color:rgba(255,71,87,.35);color:#ff4757}
    .ash-btn.danger:hover{background:rgba(255,71,87,.12);transform:translateY(-1px)}
    .ash-loading{display:flex;align-items:center;justify-content:center;gap:10px;padding:40px;color:rgba(255,255,255,.5);font-size:.95rem}
    .ash-badges-row{display:flex;align-items:center;gap:6px;flex-wrap:wrap;margin-top:2px}
    .ash-badge-dirty{background:rgba(224,184,0,.12);border-color:rgba(224,184,0,.35);color:#ffe066}
    .ash-quick-actions{display:flex;gap:6px;margin-right:auto;flex-shrink:0}
    .ash-icon-btn{width:34px;height:34px;border-radius:8px;border:1px solid;background:transparent;cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:.85rem;transition:.2s}
    .ash-icon-btn.success{border-color:rgba(46,213,115,.35);color:#2ed573}
    .ash-icon-btn.success:hover{background:rgba(46,213,115,.15);transform:translateY(-1px)}
    .ash-icon-btn.warn{border-color:rgba(255,165,0,.35);color:#ffa500}
    .ash-icon-btn.warn:hover{background:rgba(255,165,0,.15);transform:translateY(-1px)}
    .ash-icon-btn.danger{border-color:rgba(255,71,87,.35);color:#ff4757}
    .ash-icon-btn.danger:hover{background:rgba(255,71,87,.15);transform:translateY(-1px)}
    .ash-items-title{font-size:.78rem;color:rgba(255,255,255,.45);margin-bottom:4px;display:flex;align-items:center;gap:5px}
    .ash-item-dot{width:7px;height:7px;border-radius:50%;flex-shrink:0}
    .ash-empty-inv{font-size:.82rem;color:rgba(255,255,255,.35);display:flex;align-items:center;gap:6px;padding:6px 2px}
    
    /* Territory Category */
    .cat-territory{display:flex;flex-direction:column;gap:12px}
    .terr-create-card{background:rgba(255,255,255,.03);border:1px solid rgba(255,90,90,.22);border-radius:14px;padding:14px;display:flex;flex-direction:column;gap:10px}
    .terr-form-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px}
    .terr-input-wrap{display:flex;flex-direction:column;gap:6px}
    .terr-input-wrap label{font-size:.74rem;color:rgba(255,255,255,.5)}
    .terr-start-btn{border:1px solid rgba(255,88,88,.35);background:linear-gradient(135deg,rgba(130,18,18,.7),rgba(255,64,64,.35));color:#ffd7d7;border-radius:10px;padding:10px 14px;font-size:.86rem;font-weight:700;cursor:pointer;transition:.2s;display:flex;align-items:center;justify-content:center;gap:7px}
    .terr-start-btn:hover{transform:translateY(-1px);background:linear-gradient(135deg,rgba(180,22,22,.75),rgba(255,90,90,.4))}
    .terr-active-box{background:rgba(255,66,66,.08);border:1px solid rgba(255,66,66,.28);border-radius:12px;padding:10px 12px;display:flex;flex-direction:column;gap:6px}
    .terr-active-title{font-size:.84rem;font-weight:700;color:#ff8f8f;display:flex;align-items:center;gap:6px}
    .terr-active-meta{display:flex;gap:10px;flex-wrap:wrap;font-size:.77rem;color:rgba(255,255,255,.68)}
    .terr-zone-list{display:flex;flex-direction:column;gap:8px}
    .terr-zone-row{display:flex;align-items:center;justify-content:space-between;gap:10px;background:rgba(255,255,255,.025);border:1px solid rgba(255,255,255,.07);border-radius:10px;padding:10px 12px}
    .terr-zone-title{font-size:.82rem;font-weight:700;color:rgba(255,255,255,.86)}
    .terr-zone-badges{display:flex;gap:6px;flex-wrap:wrap}
    .terr-badge{display:inline-flex;align-items:center;gap:5px;padding:3px 10px;border-radius:999px;border:1px solid;font-size:.72rem;font-weight:700}
    .terr-badge.active{color:#ff7070;border-color:rgba(255,80,80,.45);background:rgba(255,50,50,.12)}
    .terr-badge.owner{background:rgba(50,170,255,.08)}
    .terr-badge.none{color:rgba(255,255,255,.55);border-color:rgba(255,255,255,.2);background:rgba(255,255,255,.04)}
    .terr-zone-cancel-full-btn{
        display:inline-flex;align-items:center;gap:5px;
        padding:3px 10px;border-radius:999px;
        border:1px solid rgba(239,68,68,.55);
        background:rgba(239,68,68,.14);color:#fca5a5;
        font-size:.72rem;font-weight:800;font-family:'Tajawal',sans-serif;
        cursor:pointer;transition:.18s ease;
    }
    .terr-zone-cancel-full-btn:hover{background:rgba(239,68,68,.28);border-color:rgba(239,68,68,.75);color:#fecaca}
    
    .territory-hint-box {
        position: fixed;
        top: 50%;
        bottom: auto;
        right: 40px;
        left: auto;
        transform: translateY(-50%);
        display: flex !important;
        flex-direction: row !important;
        align-items: center;
        gap: 10px;
        background: linear-gradient(135deg, rgba(36,10,10,0.96) 0%, rgba(52,8,8,0.96) 100%);
        border: 1px solid rgba(255, 90, 90, 0.35);
        border-radius: 14px;
        padding: 11px 18px;
        pointer-events: none;
        font-family: 'Tajawal', sans-serif;
        box-shadow:
            0 4px 24px rgba(0,0,0,0.55),
            0 0 20px rgba(255, 90, 90, 0.08) inset;
        z-index: 99998;
    }

    .territory-hint-key-badge {
        width: 30px;
        height: 30px;
        border-radius: 7px;
        background: linear-gradient(135deg, rgba(255,90,90,0.2), rgba(255,90,90,0.08));
        border: 1.5px solid rgba(255, 90, 90, 0.55);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 14px;
        font-weight: 900;
        color: #ff7c7c;
        flex-shrink: 0;
        box-shadow: 0 2px 8px rgba(255,90,90,0.2);
        text-shadow: 0 0 8px rgba(255,90,90,0.7);
    }

    .territory-hint-label {
        font-size: 13px;
        font-weight: 700;
        color: rgba(255,225,225,0.9);
        white-space: nowrap;
    }

    .territory-hint-icon {
        color: #ff7c7c;
        font-size: 16px;
        flex-shrink: 0;
        filter: drop-shadow(0 0 6px rgba(255,90,90,.6));
        animation: terrIconPulse 1.4s ease-in-out infinite alternate;
    }
    
    /* ══════════════════ TERRITORY CAPTURE OVERLAY ══════════════════ */
    .terr-capture-overlay {
        position: fixed;
        bottom: 26px;
        left: 50%;
        transform: translateX(-50%);
        width: min(360px, 92vw);
        z-index: 99999;
        pointer-events: none;
        font-family: 'Tajawal', sans-serif;
    }

    .terr-capture-panel {
        background: linear-gradient(160deg, rgba(22, 6, 6, 0.97) 0%, rgba(10, 4, 4, 0.97) 100%);
        border: 1px solid rgba(255, 77, 77, 0.28);
        border-radius: 18px;
        padding: 18px 20px 16px;
        box-shadow:
            0 0 0 1px rgba(255, 60, 60, 0.07),
            0 12px 40px rgba(0, 0, 0, 0.85),
            0 0 60px rgba(255, 60, 60, 0.06) inset;
        pointer-events: auto;
        position: relative;
        overflow: hidden;
        color: #fff;
    }

    /* top red accent line */
    .terr-capture-panel::after {
        content: '';
        position: absolute;
        top: 0; left: 10%; right: 10%;
        height: 2px;
        background: linear-gradient(90deg, transparent, #ff4d4d, transparent);
        border-radius: 0 0 4px 4px;
        animation: terrTopLine 2s ease-in-out infinite;
    }

    @keyframes terrTopLine {
        0%, 100% { opacity: .35; transform: scaleX(.55); }
        50%       { opacity: 1;  transform: scaleX(1);   }
    }

    /* subtle red glow bg */
    .terr-capture-panel::before {
        content: '';
        position: absolute;
        inset: 0;
        border-radius: 18px;
        background: linear-gradient(135deg, rgba(255,60,60,0.05) 0%, transparent 60%);
        pointer-events: none;
    }

    /* Header */
    .terr-cap-header {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 6px;
        margin-bottom: 16px;
        width: 100%;
    }

    .terr-cap-icon-wrap {
        width: 44px;
        height: 44px;
        border-radius: 12px;
        background: linear-gradient(135deg, rgba(255,60,60,0.18), rgba(100,10,10,0.45));
        border: 1px solid rgba(255,77,77,0.32);
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .terr-cap-icon {
        font-size: 20px;
        color: #ff5555;
    }

    .pulsing-red {
        animation: terrIconPulse 1.1s ease-in-out infinite alternate;
    }

    @keyframes terrIconPulse {
        from { transform: scale(1);    filter: drop-shadow(0 0 3px rgba(255,60,60,.5)); }
        to   { transform: scale(1.2);  filter: drop-shadow(0 0 12px rgba(255,60,60,.95)); }
    }

    .terr-cap-title {
        font-size: 15px;
        font-weight: 900;
        color: #fff;
        letter-spacing: .4px;
        text-align: center;
    }

    /* Timer row */
    .terr-cap-timer-row {
        display: flex;
        align-items: baseline;
        justify-content: center;
        gap: 7px;
        margin-bottom: 13px;
        padding: 10px 14px;
        background: rgba(255,255,255,0.04);
        border-radius: 10px;
        border: 1px solid rgba(255,255,255,0.06);
    }

    .terr-cap-timer-row i { font-size: 14px; color: rgba(255,100,100,.75); }
    .terr-cap-time-val    { font-size: 26px; font-weight: 900; color: #ff5555; line-height: 1; letter-spacing: .5px; }
    .terr-cap-timer-row small { font-size: 10px; opacity: .55; }

    /* Progress */
    .terr-cap-progress-section {
        display: flex;
        align-items: center;
        gap: 8px;
        margin-bottom: 13px;
    }

    .terr-cap-bar {
        flex: 1;
        height: 7px;
        background: rgba(255,255,255,0.08);
        border-radius: 999px;
        overflow: hidden;
    }

    .terr-cap-bar-fill {
        height: 100%;
        background: linear-gradient(90deg, #b91c1c, #ff5555);
        border-radius: 999px;
        transition: width 0.25s linear;
        position: relative;
    }

    .terr-cap-bar-dot {
        position: absolute;
        right: -1px;
        top: 50%;
        transform: translateY(-50%);
        width: 10px;
        height: 10px;
        background: #ff5555;
        border-radius: 50%;
        box-shadow: 0 0 6px rgba(255,85,85,.75);
    }

    .terr-cap-pct {
        font-size: 11px;
        font-weight: 700;
        color: rgba(255,100,100,.8);
        min-width: 34px;
        text-align: right;
    }

    /* Warning */
    .terr-cap-warning {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 7px;
        font-size: 11px;
        color: rgba(255,150,150,.7);
        padding: 6px 10px;
        background: rgba(255,60,60,.06);
        border: 1px solid rgba(255,60,60,.12);
        border-radius: 8px;
    }

    .terr-cap-warning i { color: #f87171; font-size: 11px; }

    /* Cancel button */
    .terr-cap-cancel-btn {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 7px;
        margin-top: 10px;
        width: 100%;
        padding: 9px 14px;
        background: rgba(220, 38, 38, 0.12);
        border: 1px solid rgba(220, 38, 38, 0.3);
        border-radius: 10px;
        color: #f87171;
        font-size: 13px;
        font-weight: 700;
        font-family: 'Tajawal', sans-serif;
        cursor: pointer;
        transition: background 0.2s, border-color 0.2s;
    }
    .terr-cap-cancel-btn:hover {
        background: rgba(220, 38, 38, 0.22);
        border-color: rgba(220, 38, 38, 0.55);
    }

    /* ── Admin cancel & capturer info ── */
    .terr-capturer-info {
        display: flex;
        align-items: center;
        gap: 6px;
        margin-top: 8px;
        padding: 6px 10px;
        background: rgba(255,160,0,.1);
        border: 1px solid rgba(255,160,0,.25);
        border-radius: 8px;
        font-size: 12px;
        color: #fcd34d;
        font-weight: 600;
    }
    .terr-capturer-gang {
        opacity: .7;
        font-size: 11px;
    }
    .terr-admin-cancel-btn {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 6px;
        margin-top: 8px;
        width: 100%;
        padding: 8px 12px;
        background: rgba(220,38,38,.12);
        border: 1px solid rgba(220,38,38,.3);
        border-radius: 9px;
        color: #fca5a5;
        font-size: 12px;
        font-weight: 700;
        font-family: 'Tajawal', sans-serif;
        cursor: pointer;
        transition: background .2s, border-color .2s;
    }
    .terr-admin-cancel-btn:hover {
        background: rgba(220,38,38,.22);
        border-color: rgba(220,38,38,.55);
    }

    /* ── Zone rename inline ── */
    .terr-zone-rename-row {
        display: flex;
        align-items: center;
        gap: 6px;
        width: 100%;
        padding: 6px 0;
    }
    .terr-rename-input {
        flex: 1;
        background: rgba(255,255,255,.06);
        border: 1px solid rgba(255,255,255,.2);
        border-radius: 7px;
        color: #f0f0f0;
        font-family: 'Tajawal', sans-serif;
        font-size: 13px;
        padding: 5px 10px;
        outline: none;
        transition: border-color .2s;
    }
    .terr-rename-input:focus { border-color: rgba(255,85,85,.5); }
    .terr-rename-confirm-btn, .terr-rename-cancel-btn {
        width: 30px; height: 30px;
        border-radius: 7px;
        border: none;
        cursor: pointer;
        font-size: 13px;
        display: flex; align-items: center; justify-content: center;
        transition: background .2s;
    }
    .terr-rename-confirm-btn {
        background: rgba(34,197,94,.18);
        color: #4ade80;
    }
    .terr-rename-confirm-btn:hover { background: rgba(34,197,94,.32); }
    .terr-rename-cancel-btn {
        background: rgba(239,68,68,.15);
        color: #f87171;
    }
    .terr-rename-cancel-btn:hover { background: rgba(239,68,68,.28); }
    .terr-rename-edit-btn {
        background: none;
        border: none;
        cursor: pointer;
        color: rgba(255,255,255,.35);
        font-size: 11px;
        padding: 2px 4px;
        border-radius: 4px;
        margin-right: 4px;
        transition: color .2s;
    }
    .terr-rename-edit-btn:hover { color: rgba(255,255,255,.8); }
    .terr-zone-delete-btn {
        background: none;
        border: none;
        cursor: pointer;
        color: rgba(248,113,113,.7);
        font-size: 11px;
        padding: 2px 4px;
        border-radius: 4px;
        transition: color .2s;
    }
    .terr-zone-delete-btn:hover { color: rgba(254,202,202,.95); }

    @media (max-width: 860px){
        .terr-form-grid{grid-template-columns:1fr}
    }
    

    /* 
       نظام الايتم الخاص  Special Item System
        */

    /* تلميح الإيداع الخاص  يرث من territory-hint-box لكن بلون ذهبي */
    .special-deposit-hint {
        border-color: rgba(255, 215, 0, 0.55) !important;
        background: linear-gradient(135deg,
            rgba(18,15,25,0.97) 0%,
            rgba(40,30,5,0.97) 100%) !important;
        box-shadow: 0 4px 32px rgba(255,215,0,0.22) !important;
    }
    .special-deposit-hint .territory-hint-key-badge {
        background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%) !important;
        color: #1a1200 !important;
    }

    /* مودال فوز الايتم الخاص */
    .special-item-modal {
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        z-index: 9999;
        width: 440px;
        padding: 40px 36px 32px;
        background: linear-gradient(160deg,
            rgba(10, 8, 20, 0.98) 0%,
            rgba(30, 22, 5, 0.98) 100%);
        border: 1.5px solid rgba(255, 215, 0, 0.45);
        border-radius: 20px;
        box-shadow:
            0 0 60px rgba(255,215,0,0.18),
            0 8px 48px rgba(0,0,0,0.7),
            inset 0 1px 0 rgba(255,215,0,0.12);
        display: flex;
        flex-direction: column;
        align-items: center;
        text-align: center;
        gap: 10px;
        pointer-events: none;
    }

    /* هالة وهج في الخلفية */
    .special-item-modal .sim-glow {
        position: absolute;
        inset: 0;
        border-radius: 20px;
        background: radial-gradient(ellipse at 50% 30%,
            rgba(255,215,0,0.1) 0%, transparent 70%);
        pointer-events: none;
    }

    .special-item-modal .sim-icon {
        font-size: 64px;
        line-height: 1;
        filter: drop-shadow(0 0 18px rgba(255,215,0,0.65));
        animation: sim-float 2.5s ease-in-out infinite;
        position: relative;
        z-index: 1;
    }

    .special-item-modal .sim-title {
        font-size: 22px;
        font-weight: 800;
        color: #FFD700;
        text-shadow: 0 0 18px rgba(255,215,0,0.55);
        letter-spacing: 0.04em;
        position: relative;
        z-index: 1;
    }

    .special-item-modal .sim-label {
        font-size: 16px;
        color: #fff;
        font-weight: 600;
        opacity: 0.92;
        position: relative;
        z-index: 1;
    }

    .special-item-modal .sim-sub {
        font-size: 12.5px;
        color: rgba(255,215,0,0.65);
        margin-top: 4px;
        line-height: 1.55;
        position: relative;
        z-index: 1;
    }

    /* أنيميشن طفو الأيقونة */
    @keyframes sim-float {
        0%, 100% { transform: translateY(0px);  }
        50%       { transform: translateY(-8px); }
    }

    /* ترانزيشن ظهور/اختفاء المودال */
    .special-item-pop-enter-active {
        animation: sim-pop-in 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) both;
    }
    .special-item-pop-leave-active {
        animation: sim-pop-out 0.4s ease-in both;
    }
    @keyframes sim-pop-in {
        from { opacity: 0; transform: translate(-50%, -50%) scale(0.6); }
        to   { opacity: 1; transform: translate(-50%, -50%) scale(1);   }
    }
    @keyframes sim-pop-out {
        from { opacity: 1; transform: translate(-50%, -50%) scale(1);   }
        to   { opacity: 0; transform: translate(-50%, -50%) scale(0.75); }
    }

/* 
   ADMIN  حساب الكنز المفقود
 */

.cat-admin-treasure {
    padding: 20px;
    display: flex;
    flex-direction: column;
    gap: 20px;
    animation: fadeIn .25s ease;
}

/* رأس الصفحة */
.tre-header {
    display: flex;
    align-items: center;
    gap: 14px;
    background: linear-gradient(135deg, rgba(231,76,60,.18), rgba(192,57,43,.08));
    border: 1px solid rgba(231,76,60,.35);
    border-radius: 14px;
    padding: 16px 20px;
}
.tre-header-icon {
    width: 48px; height: 48px;
    border-radius: 50%;
    background: linear-gradient(135deg, #e74c3c, #c0392b);
    display: flex; align-items: center; justify-content: center;
    font-size: 1.3rem; color: #fff;
    box-shadow: 0 4px 14px rgba(231,76,60,.5);
    flex-shrink: 0;
}
.tre-header-texts { flex: 1; }
.tre-header-title { font-size: 1.15rem; font-weight: 700; color: #fff; }
.tre-header-sub   { font-size: .8rem;  color: rgba(255,255,255,.55); margin-top: 2px; }

.tre-point-btn {
    margin-right: auto;
    background: linear-gradient(135deg, rgba(46, 204, 113, .28), rgba(39, 174, 96, .18));
    border: 1px solid rgba(46, 204, 113, .45);
    color: #71f3b1;
    border-radius: 10px;
    padding: 8px 12px;
    cursor: pointer;
    font-size: .82rem;
    font-family: inherit;
    display: flex;
    align-items: center;
    gap: 6px;
    transition: all .2s;
}
.tre-point-btn:hover {
    background: linear-gradient(135deg, rgba(46, 204, 113, .42), rgba(39, 174, 96, .30));
    transform: translateY(-1px);
}

.tre-refresh-btn {
    margin-right: 0;
    background: rgba(231,76,60,.2);
    border: 1px solid rgba(231,76,60,.4);
    color: #e74c3c;
    width: 38px; height: 38px;
    border-radius: 50%;
    cursor: pointer;
    font-size: .95rem;
    transition: all .2s;
    display: flex; align-items: center; justify-content: center;
}
.tre-refresh-btn:hover { background: rgba(231,76,60,.4); transform: scale(1.1); }
.tre-refresh-btn.spinning i { animation: spin 1s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

.tre-point-meta {
    margin-top: -8px;
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 10px 14px;
    border-radius: 10px;
    background: rgba(255,255,255,.04);
    border: 1px dashed rgba(255,255,255,.15);
    color: rgba(255,255,255,.8);
    font-size: .82rem;
}
.tre-point-meta i {
    color: #71f3b1;
}

/* التحميل */
.tre-loading {
    display: flex; align-items: center; justify-content: center;
    gap: 10px; padding: 60px 0;
    color: rgba(255,255,255,.5); font-size: .95rem;
}

/* شبكة البطاقات */
.tre-cards {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 16px;
}

/* بطاقة عصابة */
.tre-card {
    position: relative;
    background: rgba(255,255,255,.04);
    border: 1px solid rgba(255,255,255,.08);
    border-top: 3px solid var(--gc, #4d7fff);
    border-radius: 14px;
    padding: 16px;
    display: flex; flex-direction: column; gap: 12px;
    transition: transform .2s, box-shadow .2s;
}
.tre-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 8px 24px rgba(0,0,0,.3);
}

/* رأس البطاقة */
.tre-card-head {
    display: flex; align-items: center; gap: 10px;
}
.tre-card-logo-wrap {
    width: 40px; height: 40px; flex-shrink: 0;
    border-radius: 10px;
    background: rgba(255,255,255,.07);
    display: flex; align-items: center; justify-content: center;
    overflow: hidden;
}
.tre-card-logo {
    width: 100%; height: 100%; object-fit: contain;
}
.tre-card-info { flex: 1; min-width: 0; }
.tre-card-name {
    font-weight: 700; font-size: .95rem;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.tre-card-count {
    display: flex; align-items: center; gap: 4px; margin-top: 3px;
}
.tre-count-num {
    font-size: 1.3rem; font-weight: 800; line-height: 1;
}
.tre-count-label {
    font-size: .72rem; color: rgba(255,255,255,.45); align-self: flex-end; margin-bottom: 1px;
}

/* زر تصفير */
.tre-reset-btn {
    position: relative;
    z-index: 2;
    pointer-events: auto;
    display: flex; align-items: center; gap: 5px;
    background: rgba(231,76,60,.15);
    border: 1px solid rgba(231,76,60,.35);
    color: #e74c3c;
    border-radius: 8px;
    padding: 6px 10px;
    font-size: .78rem;
    cursor: pointer; white-space: nowrap;
    transition: all .2s;
    font-family: inherit;
}
.tre-reset-btn:hover:not(:disabled) { background: rgba(231,76,60,.35); }
.tre-reset-btn:disabled { opacity: .4; cursor: not-allowed; }

/* شريط الكنز */
.tre-bar-wrap {
    height: 4px; background: rgba(255,255,255,.1); border-radius: 99px; overflow: hidden;
}
.tre-bar-fill {
    height: 100%; border-radius: 99px;
    transition: width .5s ease;
    min-width: 4px;
}

/* صف الخصم */
.tre-deduct-row {
    display: flex; gap: 8px;
}
.tre-input {
    flex: 1;
    background: rgba(255,255,255,.07);
    border: 1px solid rgba(255,255,255,.12);
    color: #fff;
    border-radius: 8px;
    padding: 7px 12px;
    font-size: .85rem;
    outline: none;
    font-family: inherit;
    transition: border-color .2s;
    min-width: 0;
}
.tre-input:focus { border-color: rgba(255,255,255,.3); }
.tre-input::placeholder { color: rgba(255,255,255,.28); }
.tre-input::-webkit-inner-spin-button,
.tre-input::-webkit-outer-spin-button { -webkit-appearance: none; }

.tre-deduct-btn {
    position: relative;
    z-index: 2;
    pointer-events: auto;
    display: flex; align-items: center; gap: 5px;
    background: linear-gradient(135deg, rgba(52,152,219,.3), rgba(41,128,185,.2));
    border: 1px solid rgba(52,152,219,.4);
    color: #3498db;
    border-radius: 8px;
    padding: 7px 12px;
    font-size: .82rem;
    cursor: pointer; white-space: nowrap;
    transition: all .2s;
    font-family: inherit;
}
.tre-deduct-btn:hover:not(:disabled) {
    background: linear-gradient(135deg, rgba(52,152,219,.5), rgba(41,128,185,.4));
}
.tre-deduct-btn:disabled { opacity: .4; cursor: not-allowed; }

/* حالة فارغة */
.tre-empty {
    grid-column: 1/-1;
    display: flex; flex-direction: column; align-items: center;
    justify-content: center; gap: 10px;
    padding: 60px 0;
    color: rgba(255,255,255,.3);
    font-size: .9rem;
}
.tre-empty i { font-size: 2rem; }
`;

const injectRuntimeStyles = () => {
    let styleTag = document.getElementById('ahmad-gangs-runtime-style');
    if (!styleTag) {
        styleTag = document.createElement('style');
        styleTag.id = 'ahmad-gangs-runtime-style';
        document.head.appendChild(styleTag);
    }
    styleTag.textContent = RUNTIME_STYLE_CSS;
};

injectRuntimeStyles();

const DEFAULT_MENU_THEME = Object.freeze({
    primary_color: '#D1921F',
    background_color: '#0C0903',
});

const GLOBAL_THEME_OVERRIDE_CSS = `
:root{
    --menu-text-color: #FFFFFF;
    --menu-bg-rgb: 12, 9, 3;
    --menu-bg-solid: rgba(var(--menu-bg-rgb), .96);
}

.app-runtime-root,
.app-runtime-root *{
    color: var(--menu-text-color) !important;
}

.app-runtime-root,
.app-runtime-root #mainContainer,
.app-runtime-root .selector-overlay,
.app-runtime-root .selector-box,
.app-runtime-root .selector-card,
.app-runtime-root .header,
.app-runtime-root .body-layout,
.app-runtime-root .sidebar,
.app-runtime-root .sidebar-list,
.app-runtime-root .main-content,
.app-runtime-root .stats-row,
.app-runtime-root .stat-card,
.app-runtime-root .top5-box,
.app-runtime-root .member-card,
.app-runtime-root .log-row,
.app-runtime-root .modal,
.app-runtime-root .modal-box,
.app-runtime-root .confirm-box,
.app-runtime-root .shop-buy-card,
.app-runtime-root .sbc-wrap,
.app-runtime-root .tre-card,
.app-runtime-root [class*="card"],
.app-runtime-root [class*="box"],
.app-runtime-root [class*="panel"],
.app-runtime-root [class*="modal"],
.app-runtime-root [class*="overlay"],
.app-runtime-root [class*="content"],
.app-runtime-root [class*="sidebar"]{
    background: var(--menu-bg-solid) !important;
    background-image: none !important;
}
`;

const injectThemeOverrideStyles = () => {
    let styleTag = document.getElementById('ahmad-gangs-theme-override-style');
    if (!styleTag) {
        styleTag = document.createElement('style');
        styleTag.id = 'ahmad-gangs-theme-override-style';
        document.head.appendChild(styleTag);
    }
    styleTag.textContent = GLOBAL_THEME_OVERRIDE_CSS;
};

injectThemeOverrideStyles();

const clampByte = (n) => Math.max(0, Math.min(255, Math.round(Number(n) || 0)));

const normalizeHexColor = (value, fallbackHex) => {
    const fallback = String(fallbackHex || '#000000').replace('#', '');
    let hex = String(value || '').replace('#', '').replace(/[^0-9a-fA-F]/g, '');

    if (hex.length === 3) {
        hex = hex.split('').map((c) => c + c).join('');
    } else if (hex.length === 8) {
        hex = hex.slice(2);
    }

    if (hex.length !== 6) hex = fallback;
    return `#${hex.toUpperCase()}`;
};

const hexToRgb = (hexValue) => {
    const hex = normalizeHexColor(hexValue, '#000000').slice(1);
    return {
        r: parseInt(hex.slice(0, 2), 16),
        g: parseInt(hex.slice(2, 4), 16),
        b: parseInt(hex.slice(4, 6), 16),
    };
};

const rgbToHex = ({ r, g, b }) => (
    `#${clampByte(r).toString(16).padStart(2, '0')}`
    + `${clampByte(g).toString(16).padStart(2, '0')}`
    + `${clampByte(b).toString(16).padStart(2, '0')}`
).toUpperCase();

const mixRgb = (a, b, ratio) => {
    const t = Math.max(0, Math.min(1, Number(ratio) || 0));
    return {
        r: clampByte(a.r + ((b.r - a.r) * t)),
        g: clampByte(a.g + ((b.g - a.g) * t)),
        b: clampByte(a.b + ((b.b - a.b) * t)),
    };
};

const rgba = (rgb, alpha) => `rgba(${clampByte(rgb.r)},${clampByte(rgb.g)},${clampByte(rgb.b)},${alpha})`;
const rgbCsv = (rgb) => `${clampByte(rgb.r)}, ${clampByte(rgb.g)}, ${clampByte(rgb.b)}`;

const applyMenuTheme = (theme) => {
    const t = (theme && typeof theme === 'object') ? theme : {};
    const primaryHex = normalizeHexColor(t.primary_color, DEFAULT_MENU_THEME.primary_color);
    const bgHex = normalizeHexColor(t.background_color, DEFAULT_MENU_THEME.background_color);

    const primary = hexToRgb(primaryHex);
    const bg = hexToRgb(bgHex);
    const white = { r: 255, g: 255, b: 255 };
    const black = { r: 0, g: 0, b: 0 };

    const pMid = mixRgb(primary, black, 0.2);
    const pDark = mixRgb(primary, black, 0.48);
    const pBright = mixRgb(primary, white, 0.35);
    const pLight = mixRgb(primary, white, 0.2);

    const ac = mixRgb(primary, white, 0.14);
    const acMid = mixRgb(primary, black, 0.18);
    const acLight = mixRgb(primary, white, 0.34);

    const bgL1 = mixRgb(bg, white, 0.06);
    const bgL2 = mixRgb(bg, white, 0.11);
    const bgD1 = mixRgb(bg, black, 0.2);
    const bgD2 = mixRgb(bg, black, 0.33);

    const root = document.documentElement;
    root.style.setProperty('--menu-text-color', '#FFFFFF');
    root.style.setProperty('--menu-bg-rgb', rgbCsv(bg));
    root.style.setProperty('--menu-bg-solid', rgba(bg, '.96'));

    root.style.setProperty('--p', primaryHex);
    root.style.setProperty('--p-mid', rgbToHex(pMid));
    root.style.setProperty('--p-dark', rgbToHex(pDark));
    root.style.setProperty('--p-bright', rgbToHex(pBright));
    root.style.setProperty('--p-light', rgbToHex(pLight));
    root.style.setProperty('--p-rgb', rgbCsv(primary));
    root.style.setProperty('--p-dark-rgb', rgbCsv(pDark));

    root.style.setProperty('--ac', rgbToHex(ac));
    root.style.setProperty('--ac-mid', rgbToHex(acMid));
    root.style.setProperty('--ac-light', rgbToHex(acLight));
    root.style.setProperty('--ac-rgb', rgbCsv(ac));

    root.style.setProperty('--bg0', bgHex);
    root.style.setProperty('--bg1', rgba(bgL1, '.98'));
    root.style.setProperty('--bg2', rgba(bgL2, '.97'));
    root.style.setProperty('--bg3', rgba(bgD1, '.99'));
    root.style.setProperty('--bg-sb', rgba(bgD2, '.99'));
    root.style.setProperty('--bg-head', rgba(bgL1, '.98'));
    root.style.setProperty('--bg-grad1', `${rgba(bgL1, '.99')}, ${rgba(bgL2, '.99')}`);
    root.style.setProperty('--bg-grad2', `${rgba(bgD1, '.97')}, ${rgba(bgL1, '.98')}`);
    root.style.setProperty('--bg-card1', `${rgba(bgL1, '.99')}, ${rgba(bgL2, '.99')}`);
    root.style.setProperty('--bg-head-stops', `${rgba(bgL1, '.98')} 20%, ${rgba(bgL2, '.93')} 60%, ${rgba(bgD1, '.97')}`);
    root.style.setProperty('--bg-adm-head-stops', `${rgba(bgL1, '.98')} 14%, ${rgba(bgL2, '.94')} 55%, ${rgba(bgD1, '.97')}`);
};

applyMenuTheme(DEFAULT_MENU_THEME);

const app = new Vue({
    el: '#app',
    template: APP_TEMPLATE,

    data() {
        return {
            // ── Visibility ──
            show: false,

            // ── Gang Selector (multi-gang managers) ──
            gangSelector: { show: false, gangs: [] },

            // ── Current Gang ──
            gang: {
                id: '',
                label: '',
                color: '#4d7fff',
                logo: '',
                ranks: [],
                weapons: [],
                perms:    {},    // { view_all: true, hire_player: false, ... }
                warnings: [],   // active warnings from admin
            },

            // ── Active category ──
            activeCategory: 'home',

            // ════ HOME ════
            home: {
                tab: 'all',
                members: [],
                loading: false,
                search: '',
                selectedMember: null,
                totalSeconds: 0,
            },

            // Top 5 playtime — referenced as dashboard.top5 in template
            dashboard: { top5: [] },

            // ════ HIRING ════
            hiring: {
                userId: '',
                selectedRank: null,
                queryResult: null,
                loading: false,
            },

            // ════ BULK ════
            bulk: {
                message: '',
                selectedWeapon: null,
            },

            // ════ TREASURY ════
            treasury: {
                balance:       0,
                dirty_balance: 0,
                dirtyWithdrawAmt: '',
                depositAmt: '',
                withdrawAmt: '',
                log: [],
                loading: false,
            },
            // ════ DIRTY MONEY ════
            dirtyTreasury: {
                balance:         0,
                dirtyWithdrawAmt: '',
                log:             [],
                loading:         false,
            },
            // ═ Ranking ═
            ranking: {
                list:    [],
                tab:     'points',   // 'points' | 'playtime'
                loading: false,
            },
            // ═ Weapon Shop ═
            shopBuy: {
                show:      false,
                gangId:    '',
                gangName:  '',
                gangColor: '#4d7fff',
                gangLogo:  '',
                items:     [],
            },
            shopHint: false,
            shopManage: {

                loading:         false,
                owned:           false,
                territory_owned: true,
                required_points: 0,
                buy_cost:        0,
                current_points:  0,
                items:           [],
                priceInputs:     {},
            },

            territory: {
                loading: false,
                zones: [],
                activeZone: null,
                activeZones: [],
                radius: 80,
                seconds: 180,
                min_radius: 35,
                max_radius: 180,
                min_seconds: 30,
                max_seconds: 900,
                captureActive: false,
                captureLeft: 0,
                captureTotal: 0,
                captureEndsAt: 0,
                captureTimer: null,
                renameZone: { id: null, name: '' },
            },
            territoryHint: false,
            specialDepositHint: false,
            specialItemModal: {
                show:   false,
                label:  '',
                icon:   '📦',
                looted: false,
            },

            // ════ OUTFIT ════
            outfit: {
                loading:   false,
                hasOutfit: false,
                data:      null,
            },
            // ── Modals ──
            weaponPicker: {
                show: false,
                target: null,
                selected: null,
            },
            confirm: {
                show: false,
                title: '',
                body: '',
                icon: 'fa-solid fa-triangle-exclamation',
                confirmClass: 'danger',
                confirmLabel: 'تأكيد',
                amountInput: '',
                showAmountInput: false,
                inputType: 'number',
                inputPlaceholder: '',
                _cb: null,
            },

            // ── Broadcast ──
            broadcast: {
                show: false,
                gangName: '',
                gangImage: '',
                gangColor: '#4d7fff',
                message: '',
                senderName: '',
            },

            // ── Toasts ──
            toasts: [],
            _tid: 0,
            // ═ Warning Detail Modal ═
            warningDetail: {
                show:    false,
                warning: null,
            },

            _boundMessageHandler: null,
            _refreshAfterNotifyTimer: null,
            _broadcastHideTimer: null,
            _territoryLoadingFallbackTimer: null,
            _treasureLoadingFallbackTimer: null,

            // ════ ADMIN PANEL ════
            adminPanel: {
                show:           false,
                activeCategory: 'admin-overview',
                perms:          {},
                gangs:          [],
                weapons:        [],

                // ── Message ──
                message: { text: '', targetGangId: '' },

                // ── Warnings ──
                warnings: {
                    selectedGangId: '',
                    list:           [],
                    form:           { title: '', reason: '', duration: '' },
                },

                // ── Points & Ranking ──
                ranking: {
                    list:            [],
                    selectedGangId:  '',
                    pointsInput:     '',
                },

                // ── Members ──
                members: {
                    selectedGangId: '',
                    list:           [],
                    loading:        false,
                    search:         '',
                    selectedMember: null,
                },

                // ── Bulk (Pull & Weapons) ──
                bulk: {
                    selectedGangId: '',
                    selectedWeapon: null,
                },

                // ── Hire Admin ──
                hire: {
                    userId:         '',
                    selectedGangId: '',
                    selectedRank:   null,
                },

                // ── Shops & Dirty Treasury ──
                shops: {
                    list:    [],
                    loading: false,
                },

                // ── Treasure Account ──
                treasure: {
                    list:            [],
                    loading:         false,
                    hasDepositPoint: false,
                    depositPointLbl: 'غير محددة',
                },
            },

            // ════ LAUNDRY ════
            laundry: {
                active:    false,
                done:      false,
                elapsed:   0,
                total:     120,
                dirty:     0,
                clean:     0,
                _doneTimer: null,
            },
            laundryHint: false,
        };
    },

    computed: {
        /* categories visible to this manager */
        visibleCategories() {
            return ALL_CATEGORIES.filter(cat =>
                cat.perms.some(p => this.gang.perms[p])
            );
        },

        /* members filtered by current tab & search */
        filteredMembers() {
            let list = this.home.members;
            if (this.home.tab === 'online')  list = list.filter(m => m.online);
            if (this.home.tab === 'offline') list = list.filter(m => !m.online);
            const q = (this.home.search || '').trim().toLowerCase();
            if (q) list = list.filter(m =>
                (m.name || '').toLowerCase().includes(q) ||
                String(m.user_id || m.cid || '').includes(q)
            );
            return list;
        },

        onlineCount()  { return this.home.members.filter(m => m.online).length; },
        totalMembers() { return this.home.members.length; },

        totalHours() {
            const tot = Number(this.home.totalSeconds || 0);
            return Math.floor(tot / 3600);
        },
        totalMinutes() {
            const tot = Number(this.home.totalSeconds || 0);
            return Math.floor((tot % 3600) / 60);
        },

        rankingByPoints() {
            return [...(this.ranking.list || [])].sort((a, b) => (b.points || 0) - (a.points || 0));
        },

        rankingByPlaytime() {
            return [...(this.ranking.list || [])].sort((a, b) => (b.seconds || 0) - (a.seconds || 0));
        },

        /* admin visible categories */
        adminVisibleCategories() {
            return ADMIN_CATEGORIES.filter(cat =>
                cat.perms.some(p => this.adminPanel.perms[p])
            );
        },

        /* admin members filtered by search */
        adminFilteredMembers() {
            const q    = (this.adminPanel.members.search || '').trim().toLowerCase();
            const list = this.adminPanel.members.list;
            if (!q) return list;
            return list.filter(m =>
                (m.name       || '').toLowerCase().includes(q) ||
                (m.rank_label || '').toLowerCase().includes(q) ||
                String(m.user_id || m.cid || '').includes(q)
            );
        },

        /* selected gang object for hire section */
        adminSelectedGangForHire() {
            return this.adminPanel.gangs.find(g => g.id === this.adminPanel.hire.selectedGangId) || null;
        },

        /* ─── Territory Capture computed ─── */
        captureProgress() {
            if (!this.territory.captureTotal) return 0;
            const elapsed = this.territory.captureTotal - this.territory.captureLeft;
            return Math.min(100, Math.max(0, (elapsed / this.territory.captureTotal) * 100));
        },
        captureTimeLeftFmt() {
            const t = Math.max(0, this.territory.captureLeft);
            const m = Math.floor(t / 60);
            const s = t % 60;
            return `${m}:${String(s).padStart(2, '0')}`;
        },

        /* ─── Laundry computed ─── */
        laundryProgress() {
            if (!this.laundry.total) return 0;
            return Math.min(100, (this.laundry.elapsed / this.laundry.total) * 100);
        },
        laundryTimeLeft() {
            const left = Math.max(0, this.laundry.total - this.laundry.elapsed);
            const m = Math.floor(left / 60);
            const s = left % 60;
            return `${m}:${String(s).padStart(2, '0')}`;
        },
        laundryDirtyFormatted() {
            const n = this.laundry.dirty;
            return n >= 1000000 ? (n / 1000000).toFixed(1) + 'M' : n >= 1000 ? (n / 1000).toFixed(0) + 'K' : String(n);
        },
        laundryCleanFormatted() {
            const n = this.laundry.clean;
            return n >= 1000000 ? (n / 1000000).toFixed(1) + 'M' : n >= 1000 ? (n / 1000).toFixed(0) + 'K' : String(n);
        },
    },

    methods: {
        /* ─────────────── UI Control ─────────────── */
        closeUi() {
            nuiFetch('closeMenu');
            this.show = false;
        },

        cancelLaundry() {
            nuiFetch('cancelLaundry');
        },

        cancelTerritoryCapture() {
            this.showToast('warning', 'تنبيه', 'لا يمكن إلغاء الاستحلال يدويًا. الإلغاء يتم بالخروج من نطاق المنطقة فقط.');
        },

        switchCategory(id) {
            if (id === this.activeCategory) return;
            this.activeCategory = id;
            if (id === 'members')  this.loadMembers(this.home.tab || 'all');
            if (id === 'treasury') this.loadTreasury();
            if (id === 'ranking')  this.loadRanking();
            if (id === 'shop')     this.loadShopManage();
            if (id === 'dirty')    this.loadDirtyTreasury();
            if (id === 'outfit')   this.loadOutfit();
        },

        /* ─────────────── Gang Selector ─────────────── */
        selectGang(g) {
            this.gangSelector.show = false;
            nuiFetch('selectGang', { gang_id: g.id });
        },

        /* ─────────────── Home / Members ─────────────── */
        loadMembers(filter) {
            this.home.tab = filter;
            this.home.loading = true;
            this.home.selectedMember = null;
            nuiFetch('getMembers', { gang_id: this.gang.id, filter });
        },

        promoteMember(m) {
            this._openConfirm(
                'ترقية عضو', `هل تريد ترقية <b>${m.name}</b>؟`,
                'fa-solid fa-circle-up', 'info', 'ترقية',
                () => nuiFetch('promoteMember', { gang_id: this.gang.id, cid: m.cid })
            );
        },

        demoteMember(m) {
            this._openConfirm(
                'تخفيض رتبة', `هل تريد تخفيض رتبة <b>${m.name}</b>؟`,
                'fa-solid fa-circle-down', 'danger', 'تخفيض',
                () => nuiFetch('demoteMember', { gang_id: this.gang.id, cid: m.cid })
            );
        },

        pullMember(m) {
            if (!m.online) return;
            nuiFetch('pullMember', { gang_id: this.gang.id, user_id: (m.user_id || m.cid) });
        },

        /* Called from member-card action buttons */
        confirmAction(type, payload) {
            if (type === 'fireMember') {
                this._openConfirm(
                    'طرد عضو', `هل تريد طرد <b>${payload ? payload.name : ''}</b> من العصابة؟`,
                    'fa-solid fa-user-xmark', 'danger', 'طرد',
                    () => nuiFetch('fireMember', { gang_id: this.gang.id, cid: payload.cid })
                );
            } else if (type === 'firePlayer') {
                const uid = (this.hiring.userId || '').trim();
                if (!uid) return;
                this._openConfirm(
                    'فصل لاعب', `هل تريد فصل اللاعب <b>${uid}</b> من العصابة؟`,
                    'fa-solid fa-user-slash', 'danger', 'فصل',
                    () => nuiFetch('firePlayer', { gang_id: this.gang.id, user_id: uid })
                );
            } else if (type === 'pullAll') {
                this._openConfirm(
                    'سحب الجميع', 'هل تريد سحب جميع أعضاء العصابة المتواجدين إلى موقعك؟',
                    'fa-solid fa-location-arrow', 'danger', 'سحب الكل',
                    () => nuiFetch('pullAll', { gang_id: this.gang.id })
                );
            }
        },

        openWeaponPicker(m) {
            this.weaponPicker.target   = m;
            this.weaponPicker.selected = null;
            this.weaponPicker.show     = true;
        },

        confirmWeapon() {
            if (!this.weaponPicker.selected) return;
            const t = this.weaponPicker.target;
            if (t && t._admin === true) {
                nuiFetch('adminGiveWeaponGangMember', {
                    gang_id: t.gang_id,
                    user_id: (t.user_id || t.cid),
                    weapon:  this.weaponPicker.selected.weapon,
                    ammo:    this.weaponPicker.selected.ammo,
                });
            } else {
                nuiFetch('giveWeaponMember', {
                    gang_id: this.gang.id,
                    user_id: (t.user_id || t.cid),
                    weapon:  this.weaponPicker.selected.weapon,
                    ammo:    this.weaponPicker.selected.ammo,
                });
            }
            this.weaponPicker.show = false;
        },

        /* ─────────────── Hiring ─────────────── */
        queryPlayer() {
            const uid = (this.hiring.userId || '').trim();
            if (!uid) return;
            this.hiring.loading     = true;
            this.hiring.queryResult = null;
            nuiFetch('queryPlayer', { gang_id: this.gang.id, user_id: uid });
        },

        hirePlayer() {
            const uid = (this.hiring.userId || '').trim();
            if (!uid || !this.hiring.selectedRank) return;
            this._openConfirm(
                'توظيف لاعب',
                `توظيف اللاعب <b>${uid}</b> برتبة <b>${this.hiring.selectedRank.label}</b>؟`,
                'fa-solid fa-user-plus', 'info', 'توظيف',
                () => nuiFetch('hirePlayer', {
                    gang_id:   this.gang.id,
                    user_id: uid,
                    rank_code: this.hiring.selectedRank.code,
                })
            );
        },

        /* Quick actions on query result card */
        promoteMemberByCid(qr) {
            if (!qr) return;
            this._openConfirm(
                'ترقية', `ترقية <b>${qr.name}</b>؟`,
                'fa-solid fa-circle-up', 'info', 'ترقية',
                () => nuiFetch('promoteMember', { gang_id: this.gang.id, cid: qr.cid })
            );
        },
        demoteMemberByCid(qr) {
            if (!qr) return;
            this._openConfirm(
                'تخفيض', `تخفيض رتبة <b>${qr.name}</b>؟`,
                'fa-solid fa-circle-down', 'danger', 'تخفيض',
                () => nuiFetch('demoteMember', { gang_id: this.gang.id, cid: qr.cid })
            );
        },
        openWeaponPickerForQuery() {
            if (!this.hiring.queryResult) return;
            this.weaponPicker.target   = this.hiring.queryResult;
            this.weaponPicker.selected = null;
            this.weaponPicker.show     = true;
        },

        /* ─────────────── Bulk ─────────────── */
        sendMessageAll() {
            const msg = (this.bulk.message || '').trim();
            if (!msg) return;
            nuiFetch('messageAll', { gang_id: this.gang.id, message: msg });
            this.bulk.message = '';
        },

        giveWeaponAll() {
            if (!this.bulk.selectedWeapon) return;
            this._openConfirm(
                'عطاء سلاح للجميع',
                `إعطاء سلاح <b>${this.bulk.selectedWeapon.label}</b> لجميع الأعضاء المتصلين؟`,
                'fa-solid fa-gun', 'danger', 'منح السلاح',
                () => nuiFetch('giveWeaponAll', {
                    gang_id: this.gang.id,
                    weapon:  this.bulk.selectedWeapon.weapon,
                    ammo:    this.bulk.selectedWeapon.ammo,
                })
            );
        },

        /* ─────────────── Ranking ─────────────── */
        loadRanking() {
            this.ranking.loading = true;
            nuiFetch('getRanking', { gang_id: this.gang.id });
        },

        /* ─────────────── Admin Territory ─────────────── */
        adminLoadTerritory(silent = false) {
            if (!silent) this.territory.loading = false;
            nuiFetch('adminGetTerritoryData', {}).catch(() => {
                this.territory.loading = false;
            });
        },

        adminStartTerritoryBattle() {
            const radius  = parseInt(this.territory.radius);
            const seconds = parseInt(this.territory.seconds);
            if (!radius || !seconds) return;

            const rr = Math.max(this.territory.min_radius || 35, Math.min(this.territory.max_radius || 180, radius));
            const ss = Math.max(this.territory.min_seconds || 30, Math.min(this.territory.max_seconds || 900, seconds));

            this._openConfirm(
                'بدء قتال على منطقة',
                `بدء استحلال في موقعك الحالي بنطاق <b>${rr}m</b> ولمدة <b>${ss}</b> ثانية؟`,
                'fa-solid fa-crosshairs',
                'danger',
                'بدء الاستحلال',
                () => nuiFetch('adminStartTerritoryBattle', { radius: rr, seconds: ss })
            );
        },

        adminCancelTerritoryCapture(zoneId) {
            this._openConfirm(
                'سحب الاستحلال',
                'سحب عملية الاستحلال الجارية من العصابة المستحِلة؟',
                'fa-solid fa-ban',
                'danger',
                'سحب',
                () => nuiFetch('adminCancelTerritoryCapture', { zone_id: zoneId || null }).then(() => this.adminLoadTerritory(true))
            );
        },

        adminCancelTerritoryBattle(zoneId) {
            this._openConfirm(
                'إلغاء كامل للاستحلال',
                'سيتم إلغاء عملية الاستحلال بالكامل وحذف المنطقة النشطة الحالية. هل تريد المتابعة؟',
                'fa-solid fa-trash-can',
                'danger',
                'إلغاء كامل',
                () => nuiFetch('adminCancelTerritoryBattle', { zone_id: zoneId || null }).then(() => this.adminLoadTerritory(true))
            );
        },

        adminStartRenameZone(zoneId, currentLabel) {
            this.territory.renameZone = { id: zoneId, name: currentLabel };
        },

        adminCancelRenameZone() {
            this.territory.renameZone = { id: null, name: '' };
        },

        adminConfirmRenameZone(zoneId) {
            const label = (this.territory.renameZone.name || '').trim();
            if (!label) { this.showToast('warning', 'تنبيه', 'الاسم لا يمكن أن يكون فارغاً'); return; }
            nuiFetch('adminRenameTerritoryZone', { zone_id: zoneId, label });
            this.territory.renameZone = { id: null, name: '' };
        },

        adminDeleteTerritoryZone(zoneId, zoneLabel) {
            this._openConfirm(
                'حذف منطقة',
                `حذف المنطقة <b>${zoneLabel || zoneId}</b> نهائياً؟`,
                'fa-solid fa-trash',
                'danger',
                'حذف',
                () => nuiFetch('adminDeleteTerritoryZone', { zone_id: zoneId }).then(() => this.adminLoadTerritory(true))
            );
        },

        /* ────────────────── Weapon Shop ─────────────── */
        loadShopManage() {
            this.shopManage.loading = true;
            nuiFetch('getShopManage', { gang_id: this.gang.id });
        },

        shopPurchaseNow() {
            this._openConfirm(
                'شراء متجر الأسلحة',
                `شراء المتجر بتكلفة <b>${this.shopManage.buy_cost.toLocaleString()}$</b> من خزنة العصابة؟`,
                'fa-solid fa-shop', 'info', 'شراء',
                () => nuiFetch('shopPurchase', { gang_id: this.gang.id })
            );
        },

        shopRestockWeapon(item) {
            const totalCost = item.restock_price * item.restock_amount;
            this._openConfirm(
                'تعبئة مخزون',
                `تعبئة <b>${item.restock_amount}</b> قطعة من <b>${item.label}</b> بتكلفة <b>${totalCost.toLocaleString()}$</b> من خزنة العصابة؟`,
                'fa-solid fa-boxes-stacking', 'info', 'تعبئة',
                () => nuiFetch('shopRestock', { gang_id: this.gang.id, weapon: item.weapon })
            );
        },

        shopSetWeaponPrice(item) {
            const newPrice = parseInt(this.shopManage.priceInputs[item.weapon]);
            if (!newPrice || newPrice <= 0) {
                this.showToast('error', 'خطأ', 'ادخل سعراً صحيحاً');
                return;
            }
            nuiFetch('shopSetPrice', { gang_id: this.gang.id, weapon: item.weapon, price: newPrice });
            this.$set(this.shopManage.priceInputs, item.weapon, '');
        },

        closeShopBuy() {
            nuiFetch('closeShopBuy');
            this.shopBuy.show = false;
        },

        buyWeapon(item) {
            if (item.stock <= 0) return;
            this._openConfirm(
                'شراء سلاح',
                `شراء <b>${item.label}</b> بسعر <b>${item.price.toLocaleString()}$</b>؟`,
                'fa-solid fa-gun', 'info', 'شراء',
                () => nuiFetch('shopBuyWeapon', { gang_id: this.shopBuy.gangId, weapon: item.weapon })
            );
        },
        /* ─────────────── Treasury ─────────────── */
        loadTreasury() {
            this.treasury.loading = true;
            nuiFetch('getTreasury', { gang_id: this.gang.id });
        },

        loadDirtyTreasury() {
            this.dirtyTreasury.loading = true;
            nuiFetch('getTreasury', { gang_id: this.gang.id });
        },

        depositTreasury() {
            Object.assign(this.confirm, {
                show: true,
                title: 'إيداع في الخزنة',
                body: 'أدخل المبلغ المراد إيداعه في خزنة العصابة',
                icon: 'fa-solid fa-circle-plus',
                confirmClass: 'info',
                confirmLabel: 'إيداع',
                showAmountInput: true,
                amountInput: '',
                _cb: () => {
                    const amt = parseInt(this.confirm.amountInput);
                    if (isNaN(amt) || amt <= 0) return;
                    nuiFetch('treasuryDeposit', { gang_id: this.gang.id, amount: amt });
                },
            });
        },

        withdrawTreasury() {
            Object.assign(this.confirm, {
                show: true,
                title: 'سحب من الخزنة',
                body: 'أدخل المبلغ المراد سحبه من خزنة العصابة',
                icon: 'fa-solid fa-circle-minus',
                confirmClass: 'danger',
                confirmLabel: 'سحب',
                showAmountInput: true,
                amountInput: '',
                _cb: () => {
                    const amt = parseInt(this.confirm.amountInput);
                    if (isNaN(amt) || amt <= 0) return;
                    if (amt > this.treasury.balance) {
                        this.showToast('error', 'رصيد غير كافٍ', 'الخزنة لا تحتوي على هذا المبلغ');
                        return;
                    }
                    nuiFetch('treasuryWithdraw', { gang_id: this.gang.id, amount: amt });
                },
            });
        },

        withdrawDirtyAll() {
            const bal = this.dirtyTreasury.balance;
            if (bal <= 0) return;
            this._openConfirm(
                'سحب كل الأموال القذرة',
                `ستستلم <b>${bal.toLocaleString()}$</b> كعنصر أموال قذرة في مخزونك`,
                'fa-solid fa-sack-dollar', 'warning', 'سحب الكل',
                () => nuiFetch('withdrawDirty', { gang_id: this.gang.id, amount: 'all' })
            );
        },

        withdrawDirtyPartial() {
            const amt = parseInt(this.dirtyTreasury.dirtyWithdrawAmt);
            if (isNaN(amt) || amt <= 0) {
                this.showToast('warning', 'تنبيه', 'أدخل مبلغاً صحيحاً');
                return;
            }
            if (amt > this.dirtyTreasury.balance) {
                this.showToast('error', 'رصيد غير كافٍ', `الأموال القذرة لا تتجاوز ${this.dirtyTreasury.balance.toLocaleString()}$`);
                return;
            }
            this._openConfirm(
                'سحب أموال قذرة',
                `ستستلم <b>${amt.toLocaleString()}$</b> كعنصر أموال قذرة في مخزونك`,
                'fa-solid fa-sack-dollar', 'warning', 'سحب',
                () => {
                    nuiFetch('withdrawDirty', { gang_id: this.gang.id, amount: amt });
                    this.dirtyTreasury.dirtyWithdrawAmt = '';
                }
            );
        },

        /* ─────────────── Outfit System ─────────────── */
        loadOutfit() {
            this.outfit.loading = true;
            nuiFetch('getOutfitData', { gang_id: this.gang.id });
        },

        setGangOutfit() {
            this._openConfirm(
                this.outfit.hasOutfit ? 'تحديث سكن العصابة' : 'تعيين سكن العصابة',
                'سيتم حفظ مظهرك الحالي كسكن رسمي للعصابة. هل تريد المتابعة؟',
                'fa-solid fa-user-pen', 'info',
                this.outfit.hasOutfit ? 'تحديث' : 'تعيين',
                () => nuiFetch('setGangOutfit', { gang_id: this.gang.id })
            );
        },

        wearGangOutfit() {
            nuiFetch('wearGangOutfit', { gang_id: this.gang.id });
        },

        dressNearbyPlayer() {
            Object.assign(this.confirm, {
                show:             true,
                title:            'إلباس شخص سكن العصابة',
                body:             'أدخل ايدي اللاعب المراد إلباسه',
                icon:             'fa-solid fa-user-check',
                confirmClass:     'warn',
                confirmLabel:     'إلباس',
                showAmountInput:  true,
                inputType:        'number',
                inputPlaceholder: 'ايدي اللاعب...',
                amountInput:      '',
                _cb: () => {
                    const cid = parseInt(this.confirm.amountInput);
                    if (!cid || cid <= 0) return;
                    nuiFetch('dressNearbyPlayer', { gang_id: this.gang.id, cid });
                },
            });
        },

        dressGangAll() {
            this._openConfirm(
                'إلباس العصابة كلها',
                'سيتم إلباس جميع أعضاء العصابة المتصلين سكن العصابة الآن',
                'fa-solid fa-people-group', 'danger', 'تأكيد',
                () => nuiFetch('dressGangAll', { gang_id: this.gang.id })
            );
        },

        /* ─────────────── Confirm Modal ─────────────── */
        _openConfirm(title, body, icon, cls, label, cb) {
            Object.assign(this.confirm, {
                show: true, title, body, icon,
                confirmClass: cls, confirmLabel: label, _cb: cb,
                showAmountInput: false, amountInput: '',
                inputType: 'number', inputPlaceholder: '',
            });
        },

        executeConfirm() {
            if (typeof this.confirm._cb === 'function') this.confirm._cb();
            this.confirm.show = false;
            this.confirm.showAmountInput = false;
            this.confirm.amountInput = '';
        },

        /* ─────────────── Toasts ─────────────── */
        showToast(type, title, msg) {
            const container = document.getElementById('notify-container');
            if (!container) return;
            const icons = {
                success: 'fa-circle-check',
                error:   'fa-circle-xmark',
                warning: 'fa-triangle-exclamation',
            };
            const safeTitle = String(title || '').replace(/</g,'&lt;');
            const safeMsg   = String(msg   || '').replace(/</g,'&lt;');
            const box = document.createElement('div');
            box.className = 'toast-item ' + (type || 'success');
            box.style.cssText = 'opacity:0;transform:translateX(40px)';
            box.innerHTML = `
                <div class="toast-icon-wrap"><i class="fa-solid ${icons[type] || 'fa-bell'} toast-icon"></i></div>
                <div class="toast-text">
                    <div class="toast-title">${safeTitle}</div>
                    <div class="toast-msg">${safeMsg}</div>
                </div>
                <div class="toast-progress"><div class="toast-progress-bar"></div></div>
            `;
            container.appendChild(box);
            requestAnimationFrame(() => requestAnimationFrame(() => {
                box.style.transition = 'all 0.32s cubic-bezier(.34,1.56,.64,1)';
                box.style.opacity = '1';
                box.style.transform = 'translateX(0)';
            }));
            setTimeout(() => {
                box.style.transition = '0.3s ease';
                box.style.opacity = '0';
                box.style.transform = 'translateX(40px)';
                setTimeout(() => { if (box.parentNode) box.remove(); }, 320);
            }, 4500);
        },

        /* ─────────────── Broadcast ─────────────── */
        showBroadcast(data) {
            Object.assign(this.broadcast, {
                show:       true,
                gangName:   data.gang_name   || '',
                gangImage:  data.gang_image  || '',
                gangColor:  data.gang_color  || '#4d7fff',
                message:    data.message     || '',
                senderName: data.sender_name || '',
            });
            if (this._broadcastHideTimer) {
                clearTimeout(this._broadcastHideTimer);
            }
            this._broadcastHideTimer = setTimeout(() => { this.broadcast.show = false; }, 12500);
        },
        /* ──────────────── Admin Panel ──────────────── */
        closeAdmin() {
            nuiFetch('closeAdmin');
            this.adminPanel.show = false;
        },

        adminSwitchCategory(id) {
            if (id === this.adminPanel.activeCategory) return;
            this.adminPanel.activeCategory = id;
            if (id === 'admin-ranking') this.adminLoadRanking();
            if (id === 'admin-territory') this.adminLoadTerritory();
            if (id === 'admin-shops')     this.adminLoadShops();
            if (id === 'admin-treasure') this.adminLoadTreasure();
        },

        adminSelectGangForWarnings(gid) {
            this.adminPanel.warnings.selectedGangId = gid;
            this.adminPanel.warnings.list           = [];
            this.adminPanel.warnings.form           = { title: '', reason: '', duration: '' };
            nuiFetch('adminGetWarnings', { gang_id: gid });
        },

        adminAddWarning() {
            const f   = this.adminPanel.warnings.form;
            const gid = this.adminPanel.warnings.selectedGangId;
            if (!gid || !f.title.trim()) return;
            nuiFetch('adminAddWarning', {
                gang_id:  gid,
                title:    f.title.trim(),
                reason:   f.reason.trim(),
                duration: parseInt(f.duration) || 0,
            });
            f.title = ''; f.reason = ''; f.duration = '';
        },

        adminRemoveWarning(wid) {
            const gid = this.adminPanel.warnings.selectedGangId;
            this._openConfirm(
                'حذف تحذير', 'هل تريد حذف هذا التحذير؟',
                'fa-solid fa-trash', 'danger', 'حذف',
                () => nuiFetch('adminRemoveWarning', { gang_id: gid, warning_id: wid })
            );
        },

        adminLoadRanking() {
            nuiFetch('adminGetRanking', {});
        },

        adminAddPoints() {
            const gid = this.adminPanel.ranking.selectedGangId;
            const amt = parseInt(this.adminPanel.ranking.pointsInput);
            if (!gid || !amt || amt <= 0) return;
            nuiFetch('adminAddPoints', { gang_id: gid, amount: amt });
            this.adminPanel.ranking.pointsInput = '';
        },

        adminRemovePoints() {
            const gid = this.adminPanel.ranking.selectedGangId;
            const amt = parseInt(this.adminPanel.ranking.pointsInput);
            if (!gid || !amt || amt <= 0) return;
            this._openConfirm(
                'خصم نقاط', `خصم <b>${amt}</b> نقطة؟`,
                'fa-solid fa-minus', 'danger', 'خصم',
                () => {
                    nuiFetch('adminRemovePoints', { gang_id: gid, amount: amt });
                    this.adminPanel.ranking.pointsInput = '';
                }
            );
        },

        adminResetPlaytime() {
            const gid = this.adminPanel.ranking.selectedGangId;
            if (!gid) return;
            const g = this.adminPanel.gangs.find(x => x.id === gid);
            this._openConfirm(
                'تصفير التواجد',
                `هل تريد تصفير تواجد عصابة <b>${g ? g.label : gid}</b> بالكامل؟`,
                'fa-solid fa-clock-rotate-left', 'danger', 'تصفير',
                () => nuiFetch('adminResetPlaytime', { gang_id: gid })
            );
        },

        adminLoadMembers(gid) {
            this.adminPanel.members.selectedGangId = gid;
            this.adminPanel.members.list           = [];
            this.adminPanel.members.search         = '';
            this.adminPanel.members.loading        = true;
            this.adminPanel.members.selectedMember = null;
            nuiFetch('adminGetGangMembers', { gang_id: gid });
        },

        adminPromoteMember(m) {
            const gid = this.adminPanel.members.selectedGangId;
            if (!gid || !m) return;
            this._openConfirm(
                'ترقية عضو', `هل تريد ترقية <b>${m.name}</b>؟`,
                'fa-solid fa-circle-up', 'info', 'ترقية',
                () => nuiFetch('adminPromoteGangMember', { gang_id: gid, user_id: (m.user_id || m.cid) })
            );
        },

        adminDemoteMember(m) {
            const gid = this.adminPanel.members.selectedGangId;
            if (!gid || !m) return;
            this._openConfirm(
                'تنزيل رتبة', `هل تريد تنزيل رتبة <b>${m.name}</b>؟`,
                'fa-solid fa-circle-down', 'danger', 'تنزيل',
                () => nuiFetch('adminDemoteGangMember', { gang_id: gid, user_id: (m.user_id || m.cid) })
            );
        },

        adminPullMember(m) {
            const gid = this.adminPanel.members.selectedGangId;
            if (!gid || !m || !m.online) return;
            nuiFetch('adminPullGangMember', { gang_id: gid, user_id: (m.user_id || m.cid) });
        },

        adminOpenWeaponPicker(m) {
            const gid = this.adminPanel.members.selectedGangId;
            if (!gid || !m || !m.online) return;
            this.weaponPicker.target   = { ...m, _admin: true, gang_id: gid };
            this.weaponPicker.selected = null;
            this.weaponPicker.show     = true;
        },

        adminFireMember(m) {
            const gid = this.adminPanel.members.selectedGangId;
            if (!gid || !m) return;
            this._openConfirm(
                'فصل عضو', `هل تريد فصل <b>${m.name}</b> من العصابة؟`,
                'fa-solid fa-user-minus', 'danger', 'فصل',
                () => nuiFetch('adminFireGangMember', { gang_id: gid, user_id: (m.user_id || m.cid) })
            );
        },

        adminPullGang() {
            const gid = this.adminPanel.bulk.selectedGangId;
            if (!gid) return;
            const g = this.adminPanel.gangs.find(x => x.id === gid);
            this._openConfirm(
                'سحب الأعضاء', `سحب جميع أعضاء <b>${g ? g.label : gid}</b> المتصلين؟`,
                'fa-solid fa-location-arrow', 'danger', 'سحب',
                () => nuiFetch('adminPullGang', { gang_id: gid })
            );
        },

        adminGiveWeaponGang() {
            const gid = this.adminPanel.bulk.selectedGangId;
            const w   = this.adminPanel.bulk.selectedWeapon;
            if (!gid || !w) return;
            const g = this.adminPanel.gangs.find(x => x.id === gid);
            this._openConfirm(
                'توزيع عتاد', `توزيع <b>${w.label}</b> على أعضاء <b>${g ? g.label : gid}</b>؟`,
                'fa-solid fa-gun', 'danger', 'توزيع',
                () => nuiFetch('adminGiveWeaponGang', { gang_id: gid, weapon: w.weapon, ammo: w.ammo })
            );
        },

        adminSendMessage() {
            const msg = (this.adminPanel.message.text || '').trim();
            if (!msg) return;
            nuiFetch('adminMessageAllGangs', {
                message: msg,
                gang_id: this.adminPanel.message.targetGangId || '',
            });
            this.adminPanel.message.text = '';
        },

        adminHire() {
            const uid  = (this.adminPanel.hire.userId || '').trim();
            const gid  = this.adminPanel.hire.selectedGangId;
            const rank = this.adminPanel.hire.selectedRank;
            if (!uid || !gid || !rank) return;
            const g = this.adminPanel.gangs.find(x => x.id === gid);
            this._openConfirm(
                'توظيف مسؤول',
                `توظيف اللاعب <b>${uid}</b> في ${g ? g.label : gid} برتبة <b>${rank.label}</b>؟`,
                'fa-solid fa-user-shield', 'info', 'توظيف',
                () => nuiFetch('adminHireGangAdmin', { gang_id: gid, user_id: uid, rank_code: rank.code })
            );
        },

        adminFire() {
            const uid = (this.adminPanel.hire.userId || '').trim();
            const gid = this.adminPanel.hire.selectedGangId;
            if (!uid || !gid) return;
            const g = this.adminPanel.gangs.find(x => x.id === gid);
            this._openConfirm(
                'فصل من العصابة', `فصل اللاعب <b>${uid}</b> من ${g ? g.label : gid}؟`,
                'fa-solid fa-user-slash', 'danger', 'فصل',
                () => nuiFetch('adminFireGangMember', { gang_id: gid, user_id: uid })
            );
        },

        /* ─── Treasure Account ─── */
        adminLoadTreasure(silent = false) {
            if (!silent && this.adminPanel.treasure.loading) return;
            if (!silent) this.adminPanel.treasure.loading = true;

            if (this._treasureLoadingFallbackTimer) {
                clearTimeout(this._treasureLoadingFallbackTimer);
                this._treasureLoadingFallbackTimer = null;
            }

            if (!silent) {
                this._treasureLoadingFallbackTimer = setTimeout(() => {
                    if (this.adminPanel.treasure.loading) {
                        this.adminPanel.treasure.loading = false;
                    }
                    this._treasureLoadingFallbackTimer = null;
                }, 3500);
            }

            nuiFetch('adminGetTreasureData', {}).then((res) => {
                if (res && res.ok === false && this.adminPanel.treasure.loading) {
                    this.adminPanel.treasure.loading = false;
                    this.showToast('error', 'خطأ اتصال', 'فشل طلب بيانات الكنز من الواجهة');
                    if (this._treasureLoadingFallbackTimer) {
                        clearTimeout(this._treasureLoadingFallbackTimer);
                        this._treasureLoadingFallbackTimer = null;
                    }
                }
            });
        },

        adminTreasureDeduct(gangId, amount) {
            const row = this.adminPanel.treasure.list.find(x => x.gang_id === gangId);
            if (!row || row._busy) return;

            const amt = parseInt(amount, 10);
            const current = parseInt(row.count, 10) || 0;
            if (!amt || amt <= 0) {
                this.showToast('warning', 'تنبيه', 'أدخل رقم خصم صحيح');
                return;
            }
            if (amt > current) {
                this.showToast('warning', 'تنبيه', 'لا يمكن خصم أكثر من الرصيد الحالي');
                return;
            }

            this._openConfirm(
                'تأكيد الخصم',
                `خصم <b>${amt}</b> من رصيد <b>${row.label || gangId}</b>؟`,
                'fa-solid fa-minus', 'danger', 'خصم',
                () => {
                    row._busy = true;
                    if (row._pendingTimer) clearTimeout(row._pendingTimer);
                    row._pendingTimer = setTimeout(() => {
                        row._busy = false;
                        row._pendingTimer = null;
                    }, 5000);

                    this.showToast('warning', 'جاري التنفيذ', 'يتم خصم الكنز الآن...');
                    nuiFetch('adminTreasureDeduct', { gang_id: gangId, amount: amt });
                }
            );
        },

        adminTreasureReset(gangId) {
            const row = this.adminPanel.treasure.list.find(x => x.gang_id === gangId);
            if (!row || row._busy) return;
            const current = parseInt(row.count, 10) || 0;
            if (current <= 0) {
                this.showToast('warning', 'تنبيه', 'الرصيد صفر بالفعل');
                return;
            }

            this._openConfirm(
                'تأكيد التصفير',
                `تصفير رصيد الكنز بالكامل لعصابة <b>${row.label || gangId}</b>؟`,
                'fa-solid fa-trash-can', 'danger', 'تصفير',
                () => {
                    row._busy = true;
                    if (row._pendingTimer) clearTimeout(row._pendingTimer);
                    row._pendingTimer = setTimeout(() => {
                        row._busy = false;
                        row._pendingTimer = null;
                    }, 5000);

                    this.showToast('warning', 'جاري التنفيذ', 'يتم تصفير رصيد الكنز الآن...');
                    nuiFetch('adminTreasureReset', { gang_id: gangId });
                }
            );
        },

        adminSetTreasureDepositPoint() {
            nuiFetch('adminSetTreasureDepositPoint', {});
        },

        /* ─── Shops & Dirty Treasury ─── */
        adminLoadShops() {
            if (this.adminPanel.shops.loading) return;
            this.adminPanel.shops.loading = true;
            nuiFetch('adminGetShopsOverview', {});
        },

        adminToggleShop(gang_id) {
            const s = this.adminPanel.shops.list.find(x => x.gang_id === gang_id);
            if (!s) return;
            const action = s.shop_disabled ? 'إعادة فتح' : 'إغلاق مؤقت';
            this._openConfirm(
                action + ' المتجر',
                `هل تريد <b>${action}</b> متجر <b>${s.label}</b>؟`,
                s.shop_disabled ? 'fa-solid fa-lock-open' : 'fa-solid fa-lock',
                s.shop_disabled ? 'success' : 'warn',
                action,
                () => nuiFetch('adminToggleShop', { gang_id })
            );
        },

        adminDeleteShop(gang_id) {
            const s = this.adminPanel.shops.list.find(x => x.gang_id === gang_id);
            if (!s) return;
            this._openConfirm(
                'حذف المتجر نهائياً',
                `سيتم حذف متجر <b>${s.label}</b> نهائياً مع جميع المخزون والأسعار. هذا الإجراء لا يمكن التراجع عنه.`,
                'fa-solid fa-trash',
                'danger', 'حذف نهائياً',
                () => nuiFetch('adminDeleteShop', { gang_id })
            );
        },
        /* ─────────────── NUI Message Handler ─────────────── */
        _handleMessage(e) {
            const msg = e.data;
            if (!msg || !msg.type) return;

            switch (msg.type) {

                case 'openMenu': {
                    applyMenuTheme(msg.theme || {});
                    this.territoryHint = false;
                    this.laundryHint = false;
                    this.shopHint = false;
                    const managed = ((msg.data || {}).managed) || [];
                    if (managed.length > 1) {
                        this.gangSelector.gangs = managed;
                        this.gangSelector.show  = true;
                        this.show = true;
                    } else if (managed.length === 1) {
                        nuiFetch('selectGang', { gang_id: managed[0].id });
                        this.show = true;
                    } else {
                        this.showToast('error', 'خطأ', 'لا تمتلك صلاحيات إدارة أي عصابة');
                    }
                    break;
                }

                case 'gangData': {
                    const d = msg.data || {};
                    Object.assign(this.gang, {
                        id:       d.gang_id  || '',
                        label:    d.label    || '',
                        color:    d.color    || '#4d7fff',
                        logo:     d.logo     || '',
                        ranks:    d.ranks    || [],
                        weapons:  d.weapons  || [],
                        perms:    d.perms    || {},
                        warnings: d.warnings || [],
                    });
                    this.home.totalSeconds = Number(d.total_seconds) || 0;
                    this.gangSelector.show   = false;
                    this.hiring.queryResult  = null;
                    this.hiring.selectedRank = null;
                    this.territory.loading = false;
                    this.territory.zones = [];
                    this.territory.activeZone = null;
                    this.territory.activeZones = [];
                    this.activeCategory = (this.visibleCategories[0] || { id: 'home' }).id;
                    this.show = true;
                    // دائماً حمّل الأعضاء عند فتح القائمة حتى تعمل إحصائيات الرئيسية
                    this.loadMembers('all');
                    if (this.activeCategory === 'treasury') this.loadTreasury();
                    break;
                }

                case 'membersData': {
                    this.home.loading = false;
                    this.home.members = msg.members || [];
                    const totalSeconds = Number(msg.total_seconds);
                    if (Number.isFinite(totalSeconds)) {
                        this.home.totalSeconds = totalSeconds;
                    }
                    // Rebuild dashboard top5 from server-provided seconds
                    const sorted = [...this.home.members]
                        .sort((a, b) => (b.seconds || 0) - (a.seconds || 0));
                    this.dashboard.top5 = sorted.slice(0, 5).map(m => ({
                        name:    m.name,
                        hours:   m.hours   || Math.floor((m.seconds || 0) / 3600),
                        minutes: m.minutes || Math.floor(((m.seconds || 0) % 3600) / 60),
                    }));
                    break;
                }

                case 'membersRefreshNeeded': {
                    if (!this.show || this.adminPanel.show) break;
                    if (!this.gang.id || msg.gang_id !== this.gang.id) break;
                    if (this.activeCategory !== 'members') break;
                    if (this.home.loading) break;
                    this.loadMembers(this.home.tab || 'all');
                    break;
                }

                case 'queryResult': {
                    this.hiring.loading = false;
                    if (msg.ok && msg.data) {
                        this.hiring.queryResult = msg.data;
                    } else {
                        this.hiring.queryResult = null;
                        this.showToast('error', 'استعلام', msg.msg || 'لم يتم العثور على اللاعب');
                    }
                    break;
                }

                case 'treasuryData': {
                    this.treasury.loading       = false;
                    this.treasury.balance       = msg.balance       || 0;
                    this.treasury.dirty_balance = msg.dirty_balance || 0;
                    this.treasury.log           = msg.log           || [];
                    this.dirtyTreasury.loading  = false;
                    this.dirtyTreasury.balance  = msg.dirty_balance || 0;
                    this.dirtyTreasury.log      = msg.dirty_log     || [];
                    break;
                }

                case 'rankingData': {
                    this.ranking.loading = false;
                    this.ranking.list    = msg.data || [];
                    break;
                }

                case 'notify': {
                    const t    = msg.notify_type || 'success';
                    const lbl  = t === 'success' ? 'نجاح' : t === 'error' ? 'خطأ' : 'تنبيه';
                    this.showToast(t, msg.title || lbl, msg.message || '');
                    if (this._refreshAfterNotifyTimer) {
                        clearTimeout(this._refreshAfterNotifyTimer);
                    }
                    this._refreshAfterNotifyTimer = setTimeout(() => {
                        if (this.activeCategory === 'members') this.loadMembers(this.home.tab);
                        if (this.activeCategory === 'treasury') this.loadTreasury();
                        if (this.activeCategory === 'dirty')   this.loadDirtyTreasury();
                        if (this.activeCategory === 'shop') this.loadShopManage();
                        if (this.activeCategory === 'outfit') this.loadOutfit();
                        if (this.adminPanel.show && this.adminPanel.activeCategory === 'admin-members' && this.adminPanel.members.selectedGangId) {
                            this.adminLoadMembers(this.adminPanel.members.selectedGangId);
                        }
                        if (this.adminPanel.show && this.adminPanel.activeCategory === 'admin-territory') this.adminLoadTerritory(true);
                    }, 400);
                    break;
                }

                case 'broadcast': {
                    this.showBroadcast(msg);
                    break;
                }

                case 'closeMenu': {
                    this.show = false;
                    this.gangSelector.show = false;
                    // لا تصفّر حالة الاستحلال — تشتغل بشكل مستقل مثل قائمة الغسيل
                    break;
                }

                case 'territoryData': {
                    const d = msg.data || {};
                    this.territory.loading = false;
                    this.territory.zones = d.zones || [];
                    this.territory.activeZone = d.active_zone || null;
                    this.territory.activeZones = d.active_zones || (d.active_zone ? [d.active_zone] : []);
                    this.territory.radius = d.default_radius || this.territory.radius;
                    this.territory.seconds = d.default_seconds || this.territory.seconds;
                    this.territory.min_radius = d.min_radius || this.territory.min_radius;
                    this.territory.max_radius = d.max_radius || this.territory.max_radius;
                    this.territory.min_seconds = d.min_seconds || this.territory.min_seconds;
                    this.territory.max_seconds = d.max_seconds || this.territory.max_seconds;
                    break;
                }

                case 'territoryState': {
                    const d = msg.data || {};
                    if (Array.isArray(d.zones)) this.territory.zones = d.zones;
                    this.territory.activeZone = d.active_zone || null;
                    this.territory.activeZones = d.active_zones || (d.active_zone ? [d.active_zone] : []);
                    break;
                }

                case 'territoryHint': {
                    this.territoryHint = !!msg.show;
                    break;
                }

                case 'specialDepositHint': {
                    this.specialDepositHint = !!msg.show;
                    break;
                }

                case 'specialItemWon': {
                    this.specialItemModal.label  = msg.label  || 'الايتم الخاص';
                    this.specialItemModal.icon   = msg.icon   || '📦';
                    this.specialItemModal.looted = !!msg.looted;
                    this.specialItemModal.show   = true;
                    setTimeout(() => { this.specialItemModal.show = false; }, 8000);
                    break;
                }

                case 'territoryCaptureStart': {
                    const d = msg.data || {};
                    const dur = Number(d.duration) || 0;
                    this.territory.captureActive  = true;
                    this.territory.captureTotal   = dur;
                    this.territory.captureLeft    = dur;
                    this.territory.captureEndsAt  = Date.now() + (dur * 1000);

                    if (this.territory.captureTimer) {
                        clearInterval(this.territory.captureTimer);
                        this.territory.captureTimer = null;
                    }

                    this.territory.captureTimer = setInterval(() => {
                        const leftMs = this.territory.captureEndsAt - Date.now();
                        const left = Math.max(0, Math.ceil(leftMs / 1000));
                        this.territory.captureLeft = left;
                        if (left <= 0 && this.territory.captureTimer) {
                            clearInterval(this.territory.captureTimer);
                            this.territory.captureTimer = null;
                        }
                    }, 200);
                    break;
                }

                case 'territoryCaptureStop': {
                    if (this.territory.captureTimer) {
                        clearInterval(this.territory.captureTimer);
                        this.territory.captureTimer = null;
                    }
                    this.territory.captureActive = false;
                    this.territory.captureLeft = 0;
                    const ok = !!(msg.data && msg.data.success);
                    if (msg.data && msg.data.reason) {
                        this.showToast(ok ? 'success' : 'warning', ok ? 'تم الاستحلال' : 'توقف الاستحلال', msg.data.reason);
                    }
                    break;
                }

                case 'openAdmin': {
                    applyMenuTheme(msg.theme || {});
                    const d = msg.data || {};
                    this.territoryHint = false;
                    this.laundryHint = false;
                    this.shopHint = false;
                    this.adminPanel.gangs   = d.gangs   || [];
                    this.adminPanel.perms   = d.perms   || {};
                    this.adminPanel.weapons = d.weapons || [];
                    this.adminPanel.activeCategory          = 'admin-overview';
                    this.adminPanel.warnings.selectedGangId = '';
                    this.adminPanel.warnings.list           = [];
                    this.adminPanel.members.selectedGangId  = '';
                    this.adminPanel.members.list            = [];
                    this.adminPanel.members.selectedMember  = null;
                    this.adminPanel.ranking.list            = [];
                    this.adminPanel.bulk.selectedGangId     = '';
                    this.adminPanel.bulk.selectedWeapon     = null;
                    this.adminPanel.hire.userId             = '';
                    this.adminPanel.hire.selectedGangId     = '';
                    this.adminPanel.hire.selectedRank       = null;
                    this.adminPanel.shops.list       = [];
                    this.adminPanel.shops.loading    = false;
                    const warmTreasure = (d.gangs || [])
                        .filter(g => typeof g.treasure_count === 'number')
                        .map(g => ({
                            gang_id: g.id,
                            label: g.label,
                            color: g.color,
                            logo: g.logo,
                            count: g.treasure_count,
                            _deduct: null,
                            _busy: false,
                            _pendingTimer: null,
                        }))
                        .sort((a, b) => (b.count || 0) - (a.count || 0));

                    this.adminPanel.treasure.list    = warmTreasure;
                    this.adminPanel.treasure.loading = false;
                    this.adminPanel.treasure.hasDepositPoint = false;
                    this.adminPanel.treasure.depositPointLbl = 'غير محددة';
                    this.adminPanel.show = true;
                    if (this.adminPanel.perms.treasure_control) {
                        this.adminLoadTreasure(warmTreasure.length > 0);
                    }
                    break;
                }

                case 'closeAdmin': {
                    this.adminPanel.show = false;
                    this.adminPanel.treasure.loading = false;
                    if (this._treasureLoadingFallbackTimer) {
                        clearTimeout(this._treasureLoadingFallbackTimer);
                        this._treasureLoadingFallbackTimer = null;
                    }
                    break;
                }

                case 'adminWarningsData': {
                    const d = msg.data || {};
                    if (d.gang_id === this.adminPanel.warnings.selectedGangId) {
                        this.adminPanel.warnings.list = d.warnings || [];
                    }
                    break;
                }

                case 'adminRankingData': {
                    this.adminPanel.ranking.list = msg.data || [];
                    break;
                }

                case 'adminGangMembersData': {
                    const d = msg.data || {};
                    this.adminPanel.members.loading = false;
                    if (d.gang_id === this.adminPanel.members.selectedGangId) {
                        this.adminPanel.members.list = d.members || [];
                        const selected = this.adminPanel.members.selectedMember;
                        if (selected) {
                            const selectedId = selected.user_id || selected.cid;
                            this.adminPanel.members.selectedMember = this.adminPanel.members.list.find(x => (x.user_id || x.cid) === selectedId) || null;
                        }
                    }
                    break;
                }

                case 'adminPointsUpdated': {
                    const d = msg.data || {};
                    const g = this.adminPanel.gangs.find(x => x.id === d.gang_id);
                    if (g) g.points = d.points;
                    const rg = this.adminPanel.ranking.list.find(x => x.id === d.gang_id);
                    if (rg) rg.points = d.points;
                    break;
                }

                case 'adminPlaytimeReset': {
                    const d = msg.data || {};
                    const g = this.adminPanel.gangs.find(x => x.id === d.gang_id);
                    if (g) {
                        g.playtime_h = d.playtime_h || 0;
                        g.playtime_m = d.playtime_m || 0;
                    }
                    const rg = this.adminPanel.ranking.list.find(x => x.id === d.gang_id);
                    if (rg) {
                        rg.seconds = d.seconds || 0;
                        rg.playtime_h = d.playtime_h || 0;
                        rg.playtime_m = d.playtime_m || 0;
                    }
                    break;
                }

                case 'adminShopsData': {
                    this.adminPanel.shops.loading = false;
                    this.adminPanel.shops.list    = msg.data || [];
                    break;
                }

                case 'adminShopToggled': {
                    const s = this.adminPanel.shops.list.find(x => x.gang_id === msg.gang_id);
                    if (s) s.shop_disabled = !!msg.disabled;
                    break;
                }

                case 'adminShopDeleted': {
                    const s = this.adminPanel.shops.list.find(x => x.gang_id === msg.gang_id);
                    if (s) { s.shop_owned = false; s.shop_disabled = false; s.items = []; }
                    break;
                }

                case 'adminTreasureData': {
                    this.adminPanel.treasure.loading = false;
                    if (this._treasureLoadingFallbackTimer) {
                        clearTimeout(this._treasureLoadingFallbackTimer);
                        this._treasureLoadingFallbackTimer = null;
                    }
                    const payload = msg.data || [];
                    const rows = Array.isArray(payload) ? payload : (payload.list || []);
                    this.adminPanel.treasure.list = rows.map(g => ({ ...g, _deduct: null, _busy: false, _pendingTimer: null }));
                    if (!Array.isArray(payload)) {
                        this.adminPanel.treasure.hasDepositPoint = !!payload.has_point;
                        this.adminPanel.treasure.depositPointLbl = payload.point_label || 'غير محددة';
                    }
                    break;
                }

                case 'adminTreasureUpdated': {
                    const t = this.adminPanel.treasure.list.find(x => x.gang_id === msg.gang_id);
                    if (t) {
                        t.count = msg.count;
                        t._deduct = null;
                        t._busy = false;
                        if (t._pendingTimer) {
                            clearTimeout(t._pendingTimer);
                            t._pendingTimer = null;
                        }
                    }
                    break;
                }

                case 'adminTreasureDepositPointUpdated': {
                    this.adminPanel.treasure.hasDepositPoint = !!msg.has_point;
                    this.adminPanel.treasure.depositPointLbl = msg.point_label || 'غير محددة';
                    break;
                }

                case 'laundryHint': {
                    this.laundryHint = !!msg.show;
                    break;
                }

                case 'laundryStart': {
                    if (this.laundry._doneTimer) clearTimeout(this.laundry._doneTimer);
                    this.laundryHint    = false;
                    this.laundry.active  = true;
                    this.laundry.done    = false;
                    this.laundry.elapsed = 0;
                    this.laundry.total   = msg.duration || 120;
                    this.laundry.dirty   = msg.dirty    || 0;
                    this.laundry.clean   = msg.clean    || 0;
                    break;
                }

                case 'laundryTick': {
                    this.laundry.elapsed = msg.elapsed || 0;
                    break;
                }

                case 'laundryDone': {
                    this.laundry.active = false;
                    this.laundry.done   = true;
                    this.laundry.clean  = msg.clean || this.laundry.clean;
                    if (this.laundry._doneTimer) clearTimeout(this.laundry._doneTimer);
                    this.laundry._doneTimer = setTimeout(() => {
                        this.laundry.done = false;
                    }, 4000);
                    break;
                }

                case 'laundryCancelled': {
                    if (this.laundry._doneTimer) clearTimeout(this.laundry._doneTimer);
                    this.laundry.active = false;
                    this.laundry.done   = false;
                    break;
                }

                case 'shopHint': {
                    this.shopHint = !!msg.show;
                    break;
                }

                case 'openShopBuy': {
                    applyMenuTheme(msg.theme || {});
                    const sd = msg.data || {};
                    this.territoryHint = false;
                    this.laundryHint = false;
                    this.shopHint = false;
                    Object.assign(this.shopBuy, {
                        show:      true,
                        gangId:    sd.gang_id    || '',
                        gangName:  sd.gang_label || '',
                        gangColor: sd.gang_color || '#4d7fff',
                        gangLogo:  sd.gang_logo  || '',
                        items:     sd.items      || [],
                    });
                    break;
                }

                case 'shopManageData': {
                    const sm = msg.data || {};
                    this.shopManage.loading         = false;
                    this.shopManage.owned           = !!sm.owned;
                    this.shopManage.territory_owned = sm.territory_owned !== false;
                    this.shopManage.required_points = sm.required_points || 0;
                    this.shopManage.buy_cost        = sm.buy_cost         || 0;
                    this.shopManage.current_points  = sm.current_points   || 0;
                    this.shopManage.items           = sm.items            || [];
                    (sm.items || []).forEach(it => {
                        if (this.shopManage.priceInputs[it.weapon] === undefined)
                            this.$set(this.shopManage.priceInputs, it.weapon, '');
                    });
                    break;
                }

                case 'shopPurchased': {
                    const sp = msg.data || {};
                    this.shopManage.owned = true;
                    if (sp.shop_items) this.shopManage.items = sp.shop_items;
                    break;
                }

                case 'outfitData': {
                    const od = msg.data || {};
                    this.outfit.loading   = false;
                    this.outfit.hasOutfit = !!od.has_outfit;
                    this.outfit.data      = od.outfit || null;
                    break;
                }
            }
        },
    },

    mounted() {
        this._boundMessageHandler = this._handleMessage.bind(this);
        window.addEventListener('message', this._boundMessageHandler);
    },

    beforeDestroy() {
        if (this.territory && this.territory.captureTimer) {
            clearInterval(this.territory.captureTimer);
            this.territory.captureTimer = null;
        }
        if (this._refreshAfterNotifyTimer) {
            clearTimeout(this._refreshAfterNotifyTimer);
            this._refreshAfterNotifyTimer = null;
        }
        if (this._broadcastHideTimer) {
            clearTimeout(this._broadcastHideTimer);
            this._broadcastHideTimer = null;
        }
        if (this._territoryLoadingFallbackTimer) {
            clearTimeout(this._territoryLoadingFallbackTimer);
            this._territoryLoadingFallbackTimer = null;
        }
        if (this._treasureLoadingFallbackTimer) {
            clearTimeout(this._treasureLoadingFallbackTimer);
            this._treasureLoadingFallbackTimer = null;
        }
        if (this._boundMessageHandler) {
            window.removeEventListener('message', this._boundMessageHandler);
            this._boundMessageHandler = null;
        }
    },
});

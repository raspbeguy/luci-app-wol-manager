'use strict';
'require view';
'require form';
'require rpc';
'require uci';
'require ui';
'require tools.widgets as widgets';

const callHostHints = rpc.declare({
	object: 'luci-rpc',
	method: 'getHostHints',
	expect: { '': {} }
});

const callTokenNew = rpc.declare({
	object: 'wol-manager',
	method: 'token_new',
	params: [ 'user' ],
	expect: { '': {} }
});

// Fill the choices of a MultiValue with the sections of a type. The choices
// are computed on each load, so they include sections added in this session.
function sectionChoices(option, type) {
	option.load = function(section_id) {
		this.keylist = [];
		this.vallist = [];

		for (const s of uci.sections('wol_manager', type))
			this.value(s['.name'], s.name ? '%s (%s)'.format(s.name, s['.name']) : s['.name']);

		return form.MultiValue.prototype.load.call(this, section_id);
	};
}

function showToken(user, token) {
	ui.showModal(_('New token for %s').format(user), [
		E('p', _('Copy this token now. It is not shown again. The previous token of this user is no longer valid.')),
		E('pre', { 'style': 'user-select:all; white-space:pre-wrap; word-break:break-all' }, token),
		E('p', _('Example:')),
		E('pre', { 'style': 'white-space:pre-wrap; word-break:break-all' },
			'curl -H "Authorization: Bearer %s" %s/cgi-bin/wol/lists'.format(token, window.location.origin)),
		E('div', { 'class': 'right' },
			E('button', { 'class': 'btn cbi-button', 'click': ui.hideModal }, _('Close')))
	]);
}

return view.extend({
	load() {
		return callHostHints();
	},

	render(hosts) {
		let m, s, o;

		m = new form.Map('wol_manager', _('Wake-on-LAN Manager'),
			_('Users call the HTTP API with a Bearer token. Each user can wake only the hosts of the lists that are allowed for this user.'));

		s = m.section(form.NamedSection, 'globals', 'globals', _('Settings'));

		o = s.option(form.Flag, 'enabled', _('Enable API'));
		o.default = o.enabled;
		o.rmempty = false;

		o = s.option(widgets.DeviceSelect, 'iface', _('Default interface'),
			_('Network interface for the magic packets, if the host has no interface.'));
		o.noaliases = true;
		o.default = 'br-lan';
		o.rmempty = false;

		s = m.section(form.GridSection, 'host', _('Hosts'));
		s.addremove = true;
		s.anonymous = false;
		s.nodescriptions = true;

		o = s.option(form.Value, 'name', _('Description'));

		o = s.option(form.Value, 'mac', _('MAC address'));
		o.datatype = 'macaddr';
		o.rmempty = false;
		for (const mac of Object.keys(hosts).sort()) {
			const hint = hosts[mac].name ?? L.toArray(hosts[mac].ipaddrs ?? hosts[mac].ipv4)[0];
			o.value(mac, hint ? '%s (%s)'.format(mac, hint) : mac);
		}

		o = s.option(widgets.DeviceSelect, 'iface', _('Interface'));
		o.noaliases = true;
		o.optional = true;

		s = m.section(form.GridSection, 'hostlist', _('Host lists'));
		s.addremove = true;
		s.anonymous = false;
		s.nodescriptions = true;

		o = s.option(form.Value, 'name', _('Description'));

		o = s.option(form.MultiValue, 'host', _('Hosts'));
		sectionChoices(o, 'host');

		s = m.section(form.GridSection, 'user', _('Users'));
		s.addremove = true;
		s.anonymous = false;
		s.nodescriptions = true;

		o = s.option(form.Flag, 'enabled', _('Enabled'));
		o.default = o.enabled;
		o.editable = true;
		o.rmempty = false;

		o = s.option(form.MultiValue, 'allow', _('Allowed lists'));
		sectionChoices(o, 'hostlist');

		o = s.option(form.DummyValue, '_token', _('Token'));
		o.modalonly = false;
		o.editable = true;
		o.cfgvalue = (section_id) => uci.get('wol_manager', section_id, 'token_hash') ? _('set') : _('none');

		o = s.option(form.Button, '_token_new', _('New token'));
		o.inputtitle = _('Generate');
		o.inputstyle = 'apply';
		o.modalonly = false;
		o.editable = true;
		o.onclick = (ev, section_id) => callTokenNew(section_id).then((res) => {
			if (!res.token) {
				ui.addNotification(null, E('p', res.error ?? _('Cannot create the token.')), 'error');
				return;
			}

			const status = document.querySelector('output[for="cbid.wol_manager.%s._token"]'.format(section_id));
			if (status)
				status.textContent = _('set');

			showToken(section_id, res.token);
		});

		return m.render();
	}
});

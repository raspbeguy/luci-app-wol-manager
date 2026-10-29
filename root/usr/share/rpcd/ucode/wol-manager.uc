// rpcd plugin for luci-app-wol-manager. Access is limited by the
// "luci-app-wol-manager" ACL.

'use strict';

import { token_new } from 'wol_manager';

return {
	'wol-manager': {
		token_new: {
			args: { user: 'user' },
			call: function(req) {
				const token = token_new(req.args.user);

				if (!token)
					return { error: 'unknown user, save and apply the user first' };

				return { token };
			}
		}
	}
};

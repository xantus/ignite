
Ext.define('MyDesktop.EventBus', {
    extend: 'Ext.ux.desktop.Module',

    requires: [
        'Ext.window.MessageBox'
    ],

    id: 'event-bus',

    init: function() {
        this.unloading = false;
        this.buffer = [];
        this.pos = 0;
        this.cid = Ext.util.Cookies.get('cid');

        if (this.cid) {
            console.log('reusing cid:'+this.cid);
        }

        this._send = Ext.Function.createThrottled( this.sendEvent, 1000, this );

        if ( !( 'EventSource' in window ) ) {
            console.log('no event source available on this browser');
            return;
        }
    
        var events = this.source = new EventSource('sse' + ( this.cid ? '?cid=' + this.cid : '' ) );

        events.addEventListener( 'connect', Ext.bind( this.onConnect, this ) );
        events.addEventListener( 'message', Ext.bind( this.onMessage, this ) );
        events.addEventListener( 'open', Ext.bind( this.onOpen, this ) );
        //events.addEventListener( 'error', Ext.bind( this.onError, this ) );
        //events.onmessage = Ext.bind( this.onMessage, this );
        //events.onopen = Ext.bind( this.onOpen, this );
        /*
        Ext.get(window).on('unload', function() {
            this.unloading = true;
            this.sendEvent();
        }, this);
        */
    },

    onConnect: function(ev) {
        console.log('event bus - connect -', ev);
        this.cid = ev.data;
        var dt = new Date();
        dt.setFullYear( dt.getFullYear() + 3 );
        Ext.util.Cookies.set('cid', this.cid, dt);
        // bump the queue
        this._send();
    },

    onMessage: function(ev) {
        console.log('event bus - message -', ev);

        if (window.desktopApp)
            desktopApp.getDesktop().notify(ev.data,'Message');
    },

    onOpen: function(ev) {
        console.log('event bus - open -',ev.type);
        if (window.desktopApp)
            desktopApp.getDesktop().notify('connection opened', 'Event bus connection');
    },

    send: function(ev) {
        if (ev) {
            this.buffer.push( ev );
        }
        this._send();
    },

    sendEvent: function() {
        if ( !this.cid ) {
            console.log('waiting on cid');
            return;
        }

        var count = this.buffer.length;
        if (!count || this.pos > 0) {
            return;
        }

        console.log('sending count:'+count);

        this.pos = count;

        Ext.Ajax.request({
            method: 'POST',
            async: this.unloading ? false : true,
            url: 'event',
            params: {
                cid: this.cid,
                events: Ext.encode( this.buffer.slice( 0, count ) )
            },
            success: function(res){
                var text = res.responseText;
                console.log('event send - success - '+text,res.request.options.params.events);
                this.buffer.splice( 0, this.pos );
                this.pos = 0;
                this._send();
            },
            failure: function(res) {
                console.log('event send - failure -', res);
                this.pos = 0;
                this._send();
            },
            scope: this
        });
    }

});



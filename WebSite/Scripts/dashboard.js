ViewModel = function (data) {
    var self = this;
    self.name = ko.observable('');
    self.secondname = ko.observable('');
    self.sirname = ko.observable('');
    self.login = ko.observable('');
    self.password = ko.observable('');

    self.region = ko.observable();
    self.selectedRegion = ko.computed(function () {
        return self.region() ? self.region().name : '';
    });

    // Блок редактирования региона
    self.editRegion = ko.observable(false);

    self.locality = ko.observable();
    self.editLocality = ko.observable(false);

    self.street = ko.observable(new Street({ FULLNAME: '', YYYY: '0000', INDEX: '' }));
    self.editStreet = ko.observable(false);

    self.updateRegions = function () {
        $('#spinner').spin();
        $.getJSON("/Account/Region", function (data) {
            var mapped = [];
            $.map(data, function (item) { mapped.push(new Region(item)); });
            self.regions(mapped);
        }).done(function () {
            $('#spinner').spin(false);
        });
    }
    self.updateRegions();

    $("#selectedRegion").click(function () {
        self.startEditRegion();
        $("#region").focus();
    });

    $("#region").focusout(function() {
        self.endEditRegion();
    });

    $("#region").keypress(function (e) {
        if (e.which == 13) {
            self.endEditRegion();
        }
    });

    self.startEditRegion = function () {
        self.editRegion(true);
    }


    self.endEditRegion = function () {
        self.editRegion(false);
        self.locality(new Locality({ FULLNAME: 'Не выбран', CODE: self.region().code, INDEX: null }));
        self.street(new Street({ FULLNAME: 'Не выбрана', CODE: '0000', INDEX: null }));
        self.house(new House({ NAME: 'Не выбран', CODE: '0000', INDEX: null }));
        self.houseName('00');
        self.flatName('00');
    }

    // Блок редактирования населенного пункта
    self.selectedLocality = ko.computed(function () {
        return self.locality() ? self.locality().name : '';
    });

    self.updateLocalities = function (search, callback) {
        console.log(self.region());
        $('#spinner').spin();
        $.getJSON("/Account/Locality?region=" + self.region().code + '&search=' + search, function (data) {
            var mapped = [];
            $.map(data, function (item) { mapped.push(new Locality(item)); });
            if (mapped.length > 7)
                self.localities(mapped.slice(0, 7));
            else
                self.localities(mapped);
        }).done(function () {
            callback(self.localities());
            $('#spinner').spin(false);
        });
    }

    $("#selectedLocality").click(function () {
        self.startEditLocality();
        $("#locality").focus();
    });
    $("#locality").focusout(function () {
        self.endEditLocality();
    })
    $("#locality").keypress(function (e) {
        if (e.which == 13) {
            self.endEditLocality();
        }
    });

    self.startEditLocality = function () {
        self.editLocality(true);
    }

    self.hasStreet = ko.observable(true);
    self.hasHouse = ko.observable(true);
    self.endEditLocality = function () {
        self.hasStreet(false);
        self.hasHouse(false);
        console.log(self.locality());

        var code = self.locality().code;
        if (code.substring(8, 11) === '000') {
            code = code.substring(0, 8);
        }

        $.getJSON('/Account/StreetCount?locality=' + code, function (data) {
            if (data != 0)
                self.hasStreet(true);
            console.log('Улиц: ' + data);
        });
        $.getJSON('/Account/HouseCount.cshtml?street=' + code, function (data) {
            if (data != 0)
                self.hasHouse(true);
            console.log('Домов: ' + data);
        });

        self.editLocality(false);
        self.street(new Street({ FULLNAME: 'Не выбрана', CODE: '0000', INDEX: null }));
        self.house(new House({ NAME: 'Не выбран', CODE: '0000', INDEX: null }));
        self.houseName('');
        self.flatName('');
    }

    // Блок редактирования улицы
    self.selectedStreet = ko.computed(function () {
        return self.street() ? self.street().name : '';
    });

    self.updateStreets = function (search, callback) {
        var code = self.locality().code;
        if (code.substring(8, 11) === '000') {
            console.log(code);
            code = code.substring(0, 8);
            console.log(code);
        }

        console.log(self.locality());
        $('#spinner').spin();
        $.getJSON("/Account/Street?locality=" + code + '&search=' + search, function (data) {
            var mapped = [];
            $.map(data, function (item) { mapped.push(new Street(item)); });
            if (mapped.length > 10)
                self.streets(mapped.slice(0, 10));
            else
                self.streets(mapped);
        }).done(function () {
            callback(self.streets());
            $('#spinner').spin(false);
        });
    }

    $("#selectedStreet").click(function () {
        self.startEditStreet();
        $("#street").focus();
    });
    $("#street").focusout(function () {
        self.endEditStreet();
    })
    $("#street").keypress(function (e) {
        if (e.which == 13) {
            self.endEditStreet();
        }
    });

    self.startEditStreet = function () {
        self.editStreet(true);
    }

    self.endEditStreet = function () {
        if (self.street().PPP !== self.locality().code.substring(8, 11))
            self.locality().code = self.locality().code.substring(0, 8) + self.street().PPP;

        self.hasHouse(false);
        console.log(self.street());

        $.getJSON('/Account/HouseCount.cshtml?street=' + self.locality().code + self.street().code, function (data) {
            if (data != 0)
                self.hasHouse(true);
            console.log('Домов: ' + data);
        });

        self.editStreet(false);
        self.house(new House({ NAME: 'Не выбран', CODE: '0000', INDEX: null }));
        self.houseName('');
        self.flatName('');
    }

    // Блок редактирования дома
    self.houseName = ko.observable("");
    self.editHouse = ko.observable(false);
    self.house = ko.observable();
    self.selectedHouse = ko.computed(function () {
        return self.houseName();
    });

    applyCommon(self);

    $("#selectedHouse").click(function () {
        self.startEditHouse();
        $("#house").focus();
    });
    $("#house").focusout(function () {
        self.endEditHouse();
    })
    $("#house").keypress(function (e) {
        if (e.which == 13) {
            self.endEditHouse();
        }
    });


    self.flatName = ko.observable("");
    self.editFlat = ko.observable(false);
    $("#selectedFlat").click(function () {
        self.startEditFlat();
        $("#flat").focus();
    });
    $("#flat").focusout(function () {
        self.endEditFlat();
    })
    $("#flat").keypress(function (e) {
        if (e.which == 13) {
            self.endEditFlat();
        }
    });

    self.startEditFlat = function () {
        self.editFlat(true);
    }
    self.endEditFlat = function () {
        self.editFlat(false);
    }
    self.selectedFlat = ko.computed(function () {
        return self.flatName();
    });

    self.address = ko.observable("");

    self.regions = ko.observableArray([]);
    self.localities = ko.observableArray([]);
    self.streets = ko.observableArray([]);
    self.houses = ko.observableArray([]);

    self.index = ko.computed(function () {
        if (self.house() && self.house().code !== '0000' && self.house().index)
            return self.house().index;
        if (self.street() && self.street().code !== '0000' && self.street().index)
            return self.street().index;
        if (self.locality() && self.locality().code !== '0000' && self.locality().index)
            return self.locality().index;
        if (self.region())
            return self.region().index;
        return '';
    })

    self.addUser = function () {
        var data = { name: self.name(), secondname: self.secondname(), sirname: self.sirname() };
        data['locality'] = self.locality().code;
        data['street'] = self.street().code;
        data['house'] = self.house().code;
        data['houseName'] = self.houseName();
        data['flatName'] = self.flatName();
        data['login'] = self.login();
        data['password'] = self.password();

        $.post('/api/users', data, function (returnedData) {
            console.log(returnedData);
            console.log('successfully added');
            window.location.href = '/Account/EditProfile?login=' + self.login();
        })
    }

    self.isAdmin = ko.observable(false);
    //if ($('#loginValue').text().toLocaleLowerCase == "admin") {
    if ($('#loginValue').text() == "admin") {
        self.isAdmin = ko.observable(true);
    }
    self.getUser = function () {
        self.userName = ko.observable($('#loginValue').text());
        console.log($('#loginValue').text());
        $.getJSON('/api/users?login=' + $('#loginValue').text(), function (data) {
            console.log(data);
            self.name(data.NAME);
            self.secondname(data.SECONDNAME);
            self.sirname(data.SIRNAME);
            self.address(data.ADDRESS);
            $.getJSON('/Account/Object?object=region&code=' + data.LOCALITY.substring(0, 2), function (data) {
                self.region(new Region(data));
            }).done(function () {
                console.log(self.region());
            });
            $.getJSON('/Account/Object?object=locality&code=' + data.LOCALITY, function (data) {
                self.locality(new Locality(data));
            }).done(function () {
                console.log(self.locality());
            });
            if (data.STREET !== null) {
                $.getJSON('/Account/Object?object=street&code=' + data.STREET + '&loc=' + data.LOCALITY, function (data) {
                    self.street(new Street(data));
                }).done(function () {
                    console.log(self.street());
                });
            }
            if (data.HOUSE !== null) {
                $.getJSON('/Account/Object?object=house&code=' + data.LOCALITY + data.STREET + data.HOUSE, function (serverData) {
                    self.house(new House(serverData || {NAME: data.HOUSENAME}));
                }).done(function () {
                    console.log(self.house());
                });
            }
            self.houseName(data.HOUSENAME);
            self.flatName(data.FLATNAME);
            self.login(data.LOGIN);
            self.password(data.PASSWORD);
        });
    }
    self.getUser();

    self.gotUsers = ko.observableArray([]);
    self.usersToSend = ko.observableArray([]);
    self.textToSend = ko.observable("");
    self.getUsersList = function () {
        $.getJSON("/api/users", function (data) {
            var mapped = [];
            $.map(data, function (item) {
                if (item.NAME.toLowerCase() !== 'admin') {
                    mapped.push(new User(item));
                }
            });
            self.gotUsers(mapped);
            console.log(self.gotUsers());
        });
    }
    self.getUsersList();

    self.sendLetter = function () {
        var usersToSendStr = '';
        for (var j = 0; j < self.usersToSend().length; j++) {
            usersToSendStr += self.usersToSend()[j] + ';';
        }
        var query = 'users=' + usersToSendStr + '&text=' + self.textToSend();

        document.getElementById('my_iframe').src = '/api/letter?' + query;
    }
}

ko.applyBindings(new ViewModel([]));

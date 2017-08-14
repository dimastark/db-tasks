ViewModel = function (data) {
    var self = this;
    self.name = ko.observable('');
    self.secondname = ko.observable('');
    self.sirname = ko.observable('');
    self.login = ko.observable('');
    self.password = ko.observable('');

    // Блок редактирования региона
    self.region = ko.observable(new Region({ SS: '66', FULLNAME: 'Свердловская область', INDEX: '620000' }));
    self.editRegion = ko.observable(false);

    self.locality = ko.observable(new Locality({ CODE: '66000001000', FULLNAME: 'Екатеринбург город Свердловская область', INDEX: '620000' }));
    self.editLocality = ko.observable(false);

    self.street = ko.observable(new Street({ FULLNAME: 'Улица не выбрана', YYYY: '0000', INDEX: '' }));
    self.editStreet = ko.observable(false);

    self.selectedRegion = ko.computed( function( ) {
        return self.region().name;
    });

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
    $("#region").focusout(function () {
        self.endEditRegion();
    })
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
        self.houseName('');
        self.flatName('');
    }

    // Блок редактирования населенного пункта
    self.selectedLocality = ko.computed(function () {
        return self.locality().name;
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
        if (code.substring(8, 11) === '000')
            code = code.substring(0, 8);

        $.getJSON('/Account/StreetCount?locality=' + code, function (data) {
            if (data != 0)
                self.hasStreet(true);
                self.hasHouse(true);
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
        return self.street().name;
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

 // добавляем функции из common.js
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
        self.startEditRegion();
        $("#flat").focus();
    });
    $("#flat").focusout(function () {
        self.endEditRegion();
    })
    $("#flat").keypress(function (e) {
        if (e.which == 13) {
            self.endEditRegion();
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
        if (self.house() !== undefined && self.house().code !== '0000' && self.house().index != null)
            return self.house().index;
        if (self.street() !== undefined && self.street().code !== '0000' && self.street().index != null)
            return self.street().index;
        if (self.locality() !== undefined && self.locality().code !== '0000' && self.locality().index != null)
            return self.locality().index;
        return self.region().index;
    })

    self.addUser = function () {
        var data = { name: self.name(), secondname: self.secondname(), sirname: self.sirname() };
        data['locality'] = self.locality().code;
        data['street'] = self.street().code;
        data['house'] = self.house() ? self.house().code : null;
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
}

ko.applyBindings(new ViewModel([]));

 const Navbar = () => {
                return `
                <nav class="container mx-auto px-4 sm:px-6 lg:px-8">
                    <div class="flex items-center justify-between h-16">
                        <div class="flex items-center">
                            <a href="#" class="flex-shrink-0 text-2xl font-bold text-green-700 flex items-center nav-link" data-page="home">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 mr-2 text-green-500" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm4 0a1 1 0 012 0v6a1 1 0 11-2 0V8z" clip-rule="evenodd" /></svg>
                                BinBuddy
                            </a>
                            <div class="hidden md:block ml-10">
                                <div class="flex items-baseline space-x-4">
                                    <a href="#" class="nav-link text-gray-600 hover:text-green-600 px-3 py-2 rounded-md text-sm font-medium transition-colors" data-page="home">Home</a>
                                    <a href="#" class="nav-link text-gray-600 hover:text-green-600 px-3 py-2 rounded-md text-sm font-medium transition-colors" data-page="services">Services</a>
                                    <a href="#" class="nav-link text-gray-600 hover:text-green-600 px-3 py-2 rounded-md text-sm font-medium transition-colors" data-page="about">About Us</a>
                                    <a href="#" class="nav-link text-gray-600 hover:text-green-600 px-3 py-2 rounded-md text-sm font-medium transition-colors" data-page="contact">Contact</a>
                                </div>
                            </div>
                        </div>
                        <div id="auth-section" class="hidden md:block">
                            ${state.isLoggedIn ?
                                `<div class="flex items-center space-x-4">
                                    <span class="text-sm text-gray-700">Welcome, ${state.userEmail}</span>
                                    <button id="logoutBtn" class="bg-red-500 text-white px-4 py-2 rounded-full text-sm font-semibold hover:bg-red-600 transition-all shadow-sm">Logout</button>
                                </div>` :
                                `<button id="signInBtn" class="bg-green-600 text-white px-4 py-2 rounded-full text-sm font-semibold hover:bg-green-700 transition-all shadow-sm hover:shadow-lg transform hover:-translate-y-px">
                                    Sign In
                                </button>`
                            }
                        </div>
                         <div class="-mr-2 flex md:hidden">
                            <button id="mobile-menu-button" class="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-white hover:bg-green-700 focus:outline-none">
                                <svg class="h-6 w-6" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16m-7 6h7"></path>
                                </svg>
                            </button>
                        </div>
                    </div>
                     <div id="mobile-menu" class="md:hidden hidden">
                        <div class="px-2 pt-2 pb-3 space-y-1 sm:px-3">
                            <a href="#" class="nav-link text-gray-600 hover:text-green-600 block px-3 py-2 rounded-md text-base font-medium" data-page="home">Home</a>
                            <a href="#" class="nav-link text-gray-600 hover:text-green-600 block px-3 py-2 rounded-md text-base font-medium" data-page="services">Services</a>
                            <a href="#" class="nav-link text-gray-600 hover:text-green-600 block px-3 py-2 rounded-md text-base font-medium" data-page="about">About Us</a>
                            <a href="#" class="nav-link text-gray-600 hover:text-green-600 block px-3 py-2 rounded-md text-base font-medium" data-page="contact">Contact</a>
                            <div class="mt-4 pt-4 border-t border-gray-200" id="mobile-auth-section">
                            ${state.isLoggedIn ?
                                `<div class="flex flex-col space-y-3">
                                    <span class="text-sm text-gray-700 px-3">Welcome, ${state.userEmail}</span>
                                    <button id="mobileLogoutBtn" class="w-full text-left bg-red-500 text-white px-3 py-2 rounded-md text-sm font-semibold hover:bg-red-600">Logout</button>
                                </div>` :
                                `<button id="mobileSignInBtn" class="w-full text-left bg-green-600 text-white px-3 py-2 rounded-md text-sm font-semibold hover:bg-green-700">
                                    Sign In
                                </button>`
                            }
                            </div>
                        </div>
                    </div>
                </nav>
                `;
            };

           
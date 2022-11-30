import store from '@/store'
const TheView = () => import(/* webpackChunkName: "Configuration" */ './_components/TheView')

export const useRouter = $router => {
  return {
    goToCollection: () => $router.push({ name: 'interfaces' }),
    goToItem: params => $router
      .push({ name: 'routed_network', params })
      .catch(e => { if (e.name !== "NavigationDuplicated") throw e }),
    goToClone: params => $router.push({ name: 'cloneRoutedNetwork', params }),
  }
}

const can = () => !store.getters['system/isSaas']

export default [
  {
    path: 'interfaces/routed_networks/new',
    name: 'newRoutedNetwork',
    component: TheView,
    meta: {
      can
    },
    props: () => ({ isNew: true })
  },
  {
    path: 'interfaces/routed_network/:id',
    name: 'routed_network',
    component: TheView,
    meta: {
      can
    },
    props: (route) => ({ id: route.params.id }),
    beforeEnter: (to, from, next) => {
      store.dispatch('$_routed_networks/getRoutedNetwork', to.params.id).then(() => {
        next()
      })
    }
  },
  {
    path: 'interfaces/routed_network/:id/clone',
    name: 'cloneRoutedNetwork',
    component: TheView,
    meta: {
      can
    },
    props: (route) => ({ id: route.params.id, isClone: true }),
    beforeEnter: (to, from, next) => {
      store.dispatch('$_routed_networks/getRoutedNetwork', to.params.id).then(() => {
        next()
      })
    }
  }
]

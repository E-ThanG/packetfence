import apiCall from '@/utils/api'

export default {
  list: params => {
    return apiCall.get('config/admin_roles', { params }).then(({data}) => {
      return { ...data, items: data.items.filter(({id}) => !['NONE', 'ALL', 'ALL_PF_ONLY'].includes(id)) }
    })
  },
  listOptions: () => {
    return apiCall.options('config/admin_roles').then(response => {
      delete response.data.meta.allowed_actions.item.allowed // omit meta allowed_actions, fixes #5834
      return response.data
    })
  },
  item: id => {
    return apiCall.get(['config', 'admin_role', id]).then(response => {
      return response.data.item
    })
  },
  itemOptions: id => {
    return apiCall.options(['config', 'admin_role', id]).then(response => {
      return response.data
    })
  },
  create: data => {
    return apiCall.post('config/admin_roles', data).then(response => {
      return response.data
    })
  },
  update: data => {
    return apiCall.patch(['config', 'admin_role', data.id], data).then(response => {
      return response.data
    })
  },
  delete: id => {
    return apiCall.delete(['config', 'admin_role', id])
  },
  search: data => {
    return apiCall.post('config/admin_roles/search', data).then(response => {
      return response.data
    })
  }
}
